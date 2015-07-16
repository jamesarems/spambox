#line 1 "sub main::SMTPTraffic"
package main; sub SMTPTraffic {
    my $fh=shift;
    $SMTPbuf = '';
    my $ip = $Con{$fh}->{ip};
    my $pending = 0;
    eval{$pending = $fh->pending();} if ("$fh" =~ /SSL/io);
    $SMTPmaxbuf = max( $SMTPmaxbuf, 16384 , ($MaxBytes + 4096), $pending);
    $Con{$fh}->{prepend} = '';
    $Con{$fh}->{socketcalls}++;
    $fh->blocking(0) if $fh->blocking;
    &sigoffTry(__LINE__);
    my $hasread = $fh->sysread($SMTPbuf, $SMTPmaxbuf);
    &sigonTry(__LINE__);
    if ($hasread == 0 && "$fh" =~ /SSL/io && IO::Socket::SSL::errstr() =~ /SSL wants a/io) {
        ThreadYield();
        $Con{$fh}->{sslwantrw} ||= time;
        if (time - $Con{$fh}->{sslwantrw} > $SSLtimeout) {
            my $lastcmd = "- last command was \'$Con{$fh}->{lastcmd}\'";
            $lastcmd = '' unless $Con{$fh}->{lastcmd};
            mlog($fh,"info: can't read from SSL-Socket for $SSLtimeout seconds - close connection - $! $lastcmd") if ($ConnectionLog);
            delete $Con{$fh}->{sslwantrw};
            setSSLfailed($ip);
            done2($fh);
        }
        return;
    }
    delete $Con{$fh}->{sslwantrw};
    if($hasread > 0 or length($SMTPbuf) > 0) {
        my $crashfh = $Con{$fh}->{crashfh};
        if ($crashfh) {
            print $crashfh "+-+***+!+time:  ".timestring() .' / '. Time::HiRes::time()."+-+***+!+";
            print $crashfh $SMTPbuf;
        }
        if (! $ThreadDebug &&
            ( ($debugRe && $SMTPbuf =~ /($debugReRE)/) ||
              ($debugCode && eval($debugCode) && !$@)
            )
           )
        {
            if ($1||$2) {
                mlog($fh,"info: partial debug switched on - found ".($1||$2));
            } else {
                mlog($fh,"info: partial debug switched on - debugCode has returned 1");
            }
            $Con{$fh}->{debug} = 1;
            $Con{$Con{$fh}->{friend}}->{debug} = 1 if ($Con{$fh}->{friend} && exists $Con{$Con{$fh}->{friend}});
            $ThreadDebug = 1;
        }
        if ($@) {
            mlog($fh,"warning: possible syntax error in 'debugCode' - $debugCode - $@");
            mlog($fh,"warning: commending out debugCode because of syntax error");
            $debugCode = '0; # syntaxerror in : ' . $debugCode;
            $Config{debugCode} = $debugCode;
            $ConfigChanged = 1;
        }
        d('SMTPTraffic - read OK');
        $SMTPbuf=$Con{$fh}->{_}.$SMTPbuf;
        if ($Con{$fh}->{type} eq 'C'){
            $Con{$fh}->{timelast} = time;
            $Con{$fh}->{contimeoutdebug} .= "read from client = $SMTPbuf" if $ConTimeOutDebug;
        } else {
            $Con{$Con{$fh}->{friend}}->{contimeoutdebug} .= "read from server = $SMTPbuf" if $ConTimeOutDebug;
        }
        if((my $sb=$Con{$fh}->{skipbytes})>0) {

           # support for XEXCH50 thankyou Microsoft for making my life miserable
            my $l=length($SMTPbuf);
            d("skipbytes=$sb l=$l -> ");
            if($l >= $sb) {
                sendque($Con{$fh}->{friend},substr($SMTPbuf,0,$sb)); # send the binary chunk on to the server
                $SMTPbuf=substr($SMTPbuf,$sb);
                delete $Con{$fh}->{skipbytes};
            } else {
                sendque($Con{$fh}->{friend},$SMTPbuf); # send the binary chunk on to the server
                $Con{$fh}->{skipbytes}=$sb-=length($SMTPbuf);
                $SMTPbuf='';
            }
            d("skipbytes=$Con{$fh}->{skipbytes}");
        }
        d('SMTPTraffic - process read');
        my $bn= my $lbn=-1;
        if ($Con{$fh}->{type} ne 'C' or               # process line per line
            $Con{$fh}->{getline} ne \&whitebody or
            $SMTPbuf =~ /^\.(?:\x0D?\x0A)?$/o  or
            $SMTPbuf =~ /\x0D?\x0A\.\x0D?\x0A$/o)
        {
            while (($bn=index($SMTPbuf,"\n",$bn+1)) >= 0) {
                my $s=substr($SMTPbuf,$lbn+1,$bn-$lbn);
                if(defined($Con{$fh}->{bdata})) { $Con{$fh}->{bdata}-=length($s); }
                d("doing line <$s>");

                if ($Con{$fh}->{type} eq 'C') {
                    $Con{$fh}->{headerpassed} ||= $s =~ /^\x0D?\x0A/o; #header passed? if header and body in one junk
                }

                if ($Con{$fh}->{type} eq 'C' &&
                    ! $Con{$fh}->{headerpassed} &&
                    ! $Con{$fh}->{relayok})
                {
                    if ($preHeaderRe && $s =~ /($preHeaderReRE)/i) {
                        $Con{$fh}->{prepend} = '[preHeaderRE][block]';
                        mlog($fh,"early (pre)header line check found ".($1||$2));
                        NoLoopSyswrite($Con{$fh}->{friend}, "421 $myName Service not available, closing transmission channel\r\n",0) if $Con{$fh}->{friend};
                        done($fh);
                        $Stats{preHeader}++;
                        return;
                    }
                    if ($s =~ /^(X-ASSP-[^(]+?)(\(\d+\))?(:$HeaderValueRe)$/io) {  # change strange X-ASSP headers
                        my ($pre,$c,$post) = ($1,$2,$3);
                        $c =~ s/[^\d]//go;
                        $c = 0 unless $c;
                        $s = $pre . '(' . ++$c . ')' . $post;
                        $Con{$fh}->{nodkim} = 1;     # we have modified the header and should skip the DKIM check for this reason
                    }
                }
                Maillog($fh,$s,undef) if $Con{$fh}->{maillog};
                if (! $Con{$fh}->{getline}) {
                   my $lastcmd = "\'$Con{$fh}->{lastcmd}\'";
                   $lastcmd = "\'n/a\'" unless $Con{$fh}->{lastcmd};
                   mlog($fh,'error: missing $Con{$fh}->{getline} in sub SMTPTraffic (1) - last command was '.$lastcmd);
                   done($fh);
                   return;
                }
                $Con{$fh}->{getline}->($fh,$s);
                last if((exists $ConDelete{$fh} && $ConDelete{$fh}) || ! exists $Con{$fh} || $Con{$fh}->{closeafterwrite});  # it's possible that the connection can be deleted while there's still something in the buffer
                if(($Con{$fh}->{inerror} || $Con{$fh}->{intemperror}) && $Con{$fh}->{cleanSMTPBuff}) { # 4/5xx from MTA after DATA
                    $Con{$fh}->{_} = $Con{$fh}->{header} = ''; # clean the SMTP buffer
                    delete $Con{$fh}->{cleanSMTPBuff};
                    mlog($fh,"info: SMTP buffer was cleaned after MTA has sent an error reply in DATA part") if $ConnectionLog;
                    last;
                }
                $lbn=$bn;
            }
        } else {         # process the complete buf in one junk
            $Con{$fh}->{_} = '';
            $Con{$fh}->{headerpassed} = 1;
            if(defined($Con{$fh}->{bdata})) { $Con{$fh}->{bdata}-=length($SMTPbuf); }
            if (! $Con{$fh}->{getline}) {
               my $lastcmd = "\'$Con{$fh}->{lastcmd}\'";
               $lastcmd = "\'n/a\'" unless $Con{$fh}->{lastcmd};
               mlog($fh,'error: missing $Con{$fh}->{getline} in sub SMTPTraffic (2) - last command was '.$lastcmd);
               done($fh);
               return;
            }
            d("doing full <$SMTPbuf>");
            Maillog($fh,$SMTPbuf,undef) if $Con{$fh}->{maillog};
            $Con{$fh}->{getline}->($fh,$SMTPbuf);
            &NewSMTPConCall();
            return;
        }
        if(exists $Con{$fh} && ! exists $ConDelete{$fh} && ! $Con{$fh}->{closeafterwrite}) { # finish the mail as fast as possible
            ($Con{$fh}->{_})=substr($SMTPbuf,$lbn+1);
            if(length($Con{$fh}->{_}) > $MaxBytes) {
                d('SMTPTraffic - process rest');
                $Con{$fh}->{headerpassed} = 1;
                if(defined($Con{$fh}->{bdata})) { $Con{$fh}->{bdata}-=length($Con{$fh}->{_}); }
                Maillog($fh,$Con{$fh}->{_},undef) if $Con{$fh}->{maillog};
                if (! $Con{$fh}->{getline}) {
                   my $lastcmd = "\'$Con{$fh}->{lastcmd}\'";
                   $lastcmd = "\'n/a\'" unless $Con{$fh}->{lastcmd};
                   mlog($fh,'error: missing $Con{$fh}->{getline} in sub SMTPTraffic (3) - last command was '.$lastcmd);
                   done($fh);
                   return;
                }
                $Con{$fh}->{getline}->($fh,$Con{$fh}->{_});
                $Con{$fh}->{_} = '';
            }
        }
    } elsif ($hasread == 0) {
        my $error = $!;
        if ($error =~ /Resource temporarily unavailable/io) {
            d("SMTPTraffic - no more data - $error");
            return ;
        }
        if ($pending) {
            d("SMTPTraffic - got no more (SSL) data but $pending Byte are pending - $error");
            $pending = " (SSL pending = $pending)";
        } else {
            d("SMTPTraffic - no more data - $error");
            $pending = '';
        }
        eval {$ip = $fh->peerhost() . ':' . $fh->peerport();} unless $ip;
        my $lastcmd = "- last command was \'$Con{$fh}->{lastcmd}\'";
        $lastcmd = '' unless $Con{$fh}->{lastcmd};
        mlog($fh,"info: no (more) data$pending readable from $ip (connection closed by peer) - $! $lastcmd") if ($error && ($ConnectionLog or $pending));
        mlog($fh,"info: no (more) data$pending readable from $ip (connection closed by peer) $lastcmd") if (($ConnectionLog >= 2 or $pending) && ! $error);
        done2($fh);
    } else {
        my $error = $!;
        if ($pending) {
            d("SMTPTraffic - got no more (SSL) data but $pending Byte are pending - $error");
            $pending = " (SSL pending = $pending)";
        } else {
            d("SMTPTraffic - no more data - $error");
            $pending = '';
        }
        eval {$ip = $fh->peerhost() . ':' . $fh->peerport();} unless $ip;
        my $lastcmd = "- last command was \'$Con{$fh}->{lastcmd}\'";
        $lastcmd = '' unless $Con{$fh}->{lastcmd};
        mlog($fh,"error: reading from socket $ip$pending - $error $lastcmd") if ($error);
        done2($fh);
    }
    &NewSMTPConCall();
}
