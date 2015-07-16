#line 1 "sub main::reply"
package main; sub reply {
    my($fh,$l)=@_;
    d("reply - $l");
    my $this=$Con{$fh};
    return unless $this;
    my $cli=$this->{friend};
    return unless $cli;

    $l = decodeMimeWords2UTF8($l) if ($l =~ /=\?[^\?]+\?[qb]\?[^\?]*\?=/io);

    $Con{$cli}->{inerror} = ($l=~/^5[05][0-9]/o);
    $Con{$cli}->{intemperror} = ($l=~/^4\d{2}/o);
    if ($l=~/^(?:1|2|3)\d{2}/o) {
        delete $Con{$cli}->{inerror};
        delete $Con{$cli}->{intemperror};
    }

    my $cliIP = $Con{$cli}->{ip} || $cli->peerhost();
    my $serIP = $fh->peerhost();

#    $this->{lastEHLOreply} = $l if ($Con{$cli}->{lastcmd} =~ /ehlo/ig);
    
    if ( $l =~ /^220[^\-]/o && ! $Con{$cli}->{greetingSent} && $myGreeting) {
        $Con{$cli}->{greetingSent} = 1;
        $l = $myGreeting;
        $l = "220 $l" if $l !~ /^220 /o;
        $l =~ s/MYNAME/$myName/g;
        $l =~ s/VERSION/$MAINVERSION/go;
        $l =~ s/\\r/\r/go;
        $l =~ s/\\n/\n/go;
        $l =~ s/[\r\n]+$//o;
        d("send to client: $l");
        sendque($cli,"$l\r\n");
        return;
    }
    $Con{$cli}->{greetingSent} = 1 if ( $l =~ /^220[^\-]/o );
    my $DisableAUTH = $Con{$cli}->{DisableAUTH} = (exists $Con{$cli}->{DisableAUTH}) ? $Con{$cli}->{DisableAUTH} : (&matchFH($cli,@lsnNoAUTH) || ( $DisableExtAUTH && ! $Con{$cli}->{relayok} && mlog($cli,'Disabled SMTP AUTH for External IPs')));

    if ($l=~/250\s+STARTTLS/io || $l=~/250-\s*STARTTLS/io) {
        $this->{donotfakeTLS} = 1;
        if ($this->{fakeTLS}) {
            delete $this->{fakeTLS} ;
            if ($l=~/250\s+STARTTLS/io) {
                $l =~ s/250\s*STARTTLS\s*\r\n//igo;
                mlog($cli,"info: removed '250 STARTTLS' - it was already injected") if $ConnectionLog == 3;
                d("removed '250 STARTTLS' - it was already injected") if $ConnectionLog < 3;
                if(length($l)==0){
                    sendque($cli, "250 NOOP\r\n");
                    d('250 noop to client 3');
                    return;
                }
            } else {
                $l =~ s/250-\s*STARTTLS\s*\r\n//igo;
                mlog($cli,"info: removed '250-STARTTLS' - it was already injected") if $ConnectionLog == 3;
                d("removed '250-STARTTLS' - it was already injected") if $ConnectionLog < 3;
                return if(length($l)==0);
            }
        }
    }
    if ($DoTLS == 2 &&            # fake the '250 STARTTLS' if it is not supported
        $CanUseIOSocketSSL &&
        "$cli" !~ /SSL/io &&
#        ! $SSLfailed{$serIP} &&
        ! $SSLfailed{$cliIP} &&
        $Con{$cli}->{lastcmd} =~ /ehlo|help/io &&
        $l !~ /250\s+STARTTLS/io &&
        $l !~ /250-\s*STARTTLS/io &&
        $l =~ /^(?:250|211|214)/o &&
        ! $Con{$cli}->{inerror} &&
        ! $Con{$cli}->{intemperror} &&
        ! defined($Con{$cli}->{reportaddr}) &&
        ! $this->{fakeTLS} &&
        ! $this->{donotfakeTLS} &&
#        ! &matchIP($serIP,'noTLSIP',$fh,1) &&
        ! &matchIP($cliIP,'noTLSIP',$fh,1) &&
        ! &matchFH($cli,@lsnNoTLSI)
       ) {
           $l =~ /^([^\r\n]+)\r\n(.*)$/o;
           my $text1 = $1;
           my $text2 = $2;
           d('injected 250-STARTTLS');
           if ($l =~ /^(211|214)(-|\s+)/o) {
               if ($2 ne '-') {
                   $l = "$1-STARTTLS\r\n$text1\r\n$text2";
                   mlog($cli,"info: injected '$1-STARTTLS' in to HELP reply") if $ConnectionLog == 3;
               }
           } else {
               unless ($this->{fakedTLSinEHLO}) {
                   if ($text1 =~ /^250-/o) {
                       $l = "$text1\r\n250-STARTTLS\r\n$text2";
                   } else {
                       $l = "250-STARTTLS\r\n$text1\r\n$text2";
                   }
                   mlog($cli,"info: injected '250-STARTTLS' offer in to EHLO reply") if $ConnectionLog == 3;
               }
               $this->{fakeTLS} = 1;
               $this->{fakedTLSinEHLO} = 1;
           }
    }
    if ($Con{$cli}->{isTLS} && ! $this->{fakeTLS} && $l =~ /^[45]/o && uc $Con{$cli}->{lastcmd} eq 'STARTTLS') {
        $l = "250 OK\r\n";
        $this->{fakeTLS} = 1;
        d('server set fakeTLS');
    }
    if (! $Con{$cli}->{relayok} && $l =~ /^250[ \-]+(XCLIENT|XFORWARD) +(.+)\s*\r\n$/io) {
        $Con{$cli}->{uc $1} = uc $2;   # 250-XCLIENT/XFORWARD NAME ADDR PORT PROTO HELO IDENT SOURCE
        d("set client $1 to $2");
    }
    if ($l=~/250-.*?($notAllowedSMTP)/io) {
        my $cmd = $1;
        d("notAllowedSMTP: 250-sequenz - from server: \>$l\<");
        $l =~ s/250-\s*$cmd.*?\r\n//ig;
        d("notAllowedSMTP: 250-sequenz - to client: \>$l\<");
        return if(length($l)==0);
    } elsif ($l=~/250 .*?($notAllowedSMTP)/io) {
        my $cmd = $1;
        d("notAllowedSMTP: 250 sequenz - from server: \>$l\<");
        $l =~ s/250\s*$cmd.*?\r\n//ig;
        d("notAllowedSMTP: 250 sequenz - to client: \>$l\<");
        if(length($l)==0){
            sendque($cli, "250 NOOP\r\n") unless $Con{$cli}->{sentEHLO};
            d('250 noop to client 1');
            return;
        }
    } elsif($l=~/250[- ].*?SIZE\s*(\d+)/io && $maxSize && $Con{$cli}->{relayok} && $1 > $maxSize) {
        my $size = $1;
        $l =~ s/$size/$maxSize/;
        d("SIZE-offer-1: changed to $maxSize");
    } elsif($l=~/250[- ].*?SIZE\s*(\d+)/io && $maxSizeExternal && ! $Con{$cli}->{relayok} && $1 > $maxSizeExternal) {
        my $size = $1;
        $l =~ s/$size/$maxSizeExternal/;
        d("SIZE-offer-2: changed to $maxSizeExternal");
    } elsif($l=~/250-\s*(?:VRFY|EXPN)/io && $DisableVRFY && !$Con{$cli}->{relayok}) {        # VRFY EXPN
        d("250-sequenz - from server: \>$l\<");
        $l =~ s/250-\s*(?:VRFY|EXPN)\s*\r\n//igo;
        d("250-sequenz - to client: \>$l\<");
        return if(length($l)==0);
    } elsif($l=~/250\s+(?:VRFY|EXPN)/io && $DisableVRFY && !$Con{$cli}->{relayok}) {
        d("250 sequenz - from server: \>$l\<");
        $l =~ s/250\s*(?:VRFY|EXPN)\s*\r\n//igo;
        d("250 sequenz - to client: \>$l\<");
        if(length($l)==0){
            sendque($cli, "250 NOOP\r\n") unless $Con{$cli}->{sentEHLO};
            d('250 noop to client 1-1');
            return;
        }
    } elsif($l=~/250-\s*AUTH/io && $DisableAUTH && !$Con{$cli}->{relayok}) {        # AUTH
        d("250-sequenz - from server: \>$l\<");
        d("250-sequenz - to client: \>\<");
        return;
    } elsif($l=~/250\s+AUTH/io && $DisableAUTH && !$Con{$cli}->{relayok}) {
        d("250 sequenz - from server: \>$l\<");
        d("250 sequenz - to client: \>NOOP\<");
        sendque($cli, "250 NOOP\r\n") unless $Con{$cli}->{sentEHLO};
        return;
    } elsif (($l=~/(211|214)(?: |-)(?:.*?)(?:VRFY|EXPN)/io && $DisableVRFY && !$Con{$cli}->{relayok}) or
             ($l=~/(211|214)(?: |-)(?:.*?)AUTH/io && $DisableAUTH && !$Con{$cli}->{relayok}) or
             ($l=~/(211|214)(?: |-)(?:.*?)(?:$notAllowedSMTP)/io) ) {
        d("$1 sequenz - from server: \>$l\<");
        $l =~ s/VRFY|EXPN//sigo if ($DisableVRFY && !$Con{$cli}->{relayok});
        $l =~ s/AUTH[^\r\n]+//sigo if ($DisableAUTH && !$Con{$cli}->{relayok});
        $l =~ s/$notAllowedSMTP/NOOP/sigo;
    } elsif ($l=~/250[\s\-]+AUTH[\s\=]+(.+)/io) {
        my $methodes = $1;
        $methodes =~ s/^\s+//o;
        $methodes =~ s/[\s\r\n]+$//o;
        foreach (split(/\s+/o,$methodes)) {
            $Con{$cli}->{authmethodes}->{uc $_} = 1;
            d("info: Reply: registered authmethode $_");
        }
    } elsif ($l=~/250\s+STARTTLS/io || $l=~/250-\s*STARTTLS/io) {
        if (! $DoTLS ||
#            $SSLfailed{$serIP} ||
#            &matchIP($serIP,'noTLSIP',$fh,1) ||
            $SSLfailed{$cliIP} ||
            &matchIP($cliIP,'noTLSIP',$fh,1) ||
            &matchFH($cli,@lsnNoTLSI))
        {
            $l =~ s/250(-|\s)\s*STARTTLS\s*\r\n//igo;
            if(length($l)==0) {
                $l = "250$1"."NOOP\r\n";
                d('noop to client 2');
            }
            mlog($cli,"info: removed '250$1STARTTLS' from reply") if $ConnectionLog >= 2;
            d("removed '250$1STARTTLS' from reply") if $ConnectionLog < 2;
            sendque($cli, $l);
            return;
        } else {
            $this->{isTLS} = 1;
            my $fa = $this->{fakeTLS} ? 'injected' : 'got';
            my $fr = $this->{fakeTLS} ? 'for' : 'from';
            mlog($cli,"info: send '250-STARTTLS' - $fa $fr $serIP") if $ConnectionLog >= 2;
            d("send '250-STARTTLS' - $fa $fr $serIP") if $ConnectionLog < 2;
            sendque($cli, $l) unless $Con{$cli}->{sentEHLO};
            return;
        }
    } elsif($l=~/^220[^\-]/o or ($l=~/^250[^\-]/o and ($this->{fakeTLS} or $this->{donotfakeTLS}))) {
        if ($Con{$cli}->{isTLS} && ! $this->{isTLS}) {
            d('STARTTLS request without STARTTLS offer from server');

         # STARTTLS from Client but there was no 250-STARTTLS from server before
         # hola: we have got 220 - this works but is not RFC 4954 conform

            #   S: 220 mail.imc.org SMTP service ready
            #   C: EHLO mail.ietf.org
            #   S: 250 mail.imc.org offers a warm hug of welcome
            #   C: STARTTLS
            #   S: 220 Go ahead
        }

     #   if ($Con{$cli}->{isTLS} && $this->{isTLS})    # RFC 4954 conform check
        if ($Con{$cli}->{isTLS}) {
            # RFC 4954
            # there was something like that up to here

            #   S: 220 mail.imc.org SMTP service ready
            #   C: EHLO mail.ietf.org
            #   S: 250-mail.imc.org offers a warm hug of welcome
            #   S: 250 STARTTLS  or  250-STARTTLS
            #   C: STARTTLS
            #   S: 220 Go ahead

            # set client and Server to transparent Proxy mode and send $l
            # from here we do not care about what is done between this two peers
            # even if the TLS negotation will fail - a SPAM comes never with TLS
            delete $this->{isTLS};
            delete $Con{$cli}->{isTLS};
            binmode($fh);
            binmode($cli);
            &dopoll($cli,$readable,POLLIN);
            &dopoll($cli,$writable,POLLOUT);
            &dopoll($fh,$readable,POLLIN);
            &dopoll($fh,$writable,POLLOUT);
            $Con{$fh}->{paused}=0;
            $Con{$cli}->{paused}=0;
            $Con{$fh}->{timelast} = time;
            $Con{$cli}->{timelast} = $Con{$fh}->{timelast};
            $Con{$fh}->{runTLS}=1;
            $Con{$cli}->{runTLS}=1;
            delete $this->{noop};

          if ($DoTLS == 1 or &matchFH($cli,@TLStoProxyI)) {      # move to transparent proxy
            delete $this->{fakeTLS};
            $Con{$cli}->{outgoing}.=$l;
            $SocketCalls{$fh}=\&ProxyTraffic;
            $SocketCalls{$cli}=\&ProxyTraffic;
            mlog($cli,"info: started TLS-proxy session for $serIP and $cliIP") if $ConnectionLog >= 2;
            d("started TLS-proxy session for $serIP and $cliIP") if $ConnectionLog < 2;;
            return;
          } elsif ($DoTLS == 2 && $CanUseIOSocketSSL) {                   #  do TLS
            $IO::Socket::SSL::DEBUG = $SSLDEBUG;
            my $oldfh = "$fh";
            my $sslc;
            my $ssls;
            my $oldcli = "$cli";
            if ($this->{fakeTLS}) {    # only set Client to TLS if we faked the 250-STARTTLS
              if ("$cli" !~ /SSL/io) {
                NoLoopSyswrite($cli, "220 Ready to start TLS\r\n",0);
                # set the client connection to SSL
                unpoll($cli,$readable);
                unpoll($cli,$writable);
                my $fail = 0;
                eval{eval{($ssls,$cli) = &switchSSLClient($cli);};
                    if ("$ssls" !~ /SSL/io ) {
                         $fail = 1;
                         mlog($cli, "error: Couldn't upgrade to TLS for client $cliIP: ".IO::Socket::SSL::errstr());
                         setSSLfailed($cliIP);
                         delete $this->{fakeTLS};
                         &dopoll($cli,$readable,POLLIN);
                         &dopoll($cli,$writable,POLLOUT);
                    }
                };
                return if $fail;
                
                delete $SSLfailed{$cliIP};
                addsslfh($oldcli,$ssls,$fh);
                mlog($ssls,"info: started TLS-SSL session for client $cliIP") if ($ConnectionLog >= 2);
              }
            } else {
                # set the client and the server connection to SSL if not already
              if ("$cli" !~ /SSL/io && ! $SSLfailed{$cliIP} && ! &matchIP($cliIP,'noTLSIP',$fh,1) && ! &matchFH($cli,@lsnNoTLSI)) {
                NoLoopSyswrite($cli, $l,0);
                unpoll($cli,$readable);
                unpoll($cli,$writable);
                my $fail = 0;
                eval{eval{($ssls,$cli) = &switchSSLClient($cli);};
                    if ("$ssls" !~ /SSL/io ) {
                         $fail = 1;
                         mlog($cli, "error: Couldn't upgrade to TLS for client $cliIP: ".IO::Socket::SSL::errstr());
                         setSSLfailed($cliIP);
                         delete $this->{fakeTLS};
                         &dopoll($cli,$readable,POLLIN);
                         &dopoll($cli,$writable,POLLOUT);
                    }
                };
                return if $fail;

                delete $SSLfailed{$cliIP};
                addsslfh($oldcli,$ssls,$fh);
                mlog($ssls,"info: started TLS-SSL session for client $cliIP") if ($ConnectionLog >= 2);
              } else {
                NoLoopSyswrite($cli, "502 command not implemented\r\n",0);
              }

              if ("$fh" !~ /SSL/io && ! $SSLfailed{$serIP} && ! &matchIP($serIP,'noTLSIP',$fh,1) && ! &matchFH($fh,@lsnNoTLSI)) {
                unpoll($fh,$readable);
                unpoll($fh,$writable);
                my $fail = 0;
                eval{eval{($sslc,$fh) = &switchSSLServer($fh);};
                    if ("$sslc" !~ /SSL/io) {
                      $fail = 1;
                      mlog($fh, "error: Couldn't start TLS for server $serIP: ".IO::Socket::SSL::errstr());
                      setSSLfailed($serIP);
                      delete $this->{fakeTLS};
                      &dopoll($fh,$readable,POLLIN);
                      &dopoll($fh,$writable,POLLOUT);
                    }
                };
                return if $fail;
                
                delete $SSLfailed{$serIP};
                addsslfh($oldfh,$sslc,$ssls);
                $Con{$ssls}->{friend} = $sslc;
                mlog($sslc,"info: started TLS-SSL session for server $serIP") if ($ConnectionLog >= 2);
              }
            }
            delete $this->{fakeTLS};
            delete $Con{$sslc}->{fakeTLS};
            return;
          }
        } else {
            if ($this->{noop} ne 'delete') {
                sendque($fh,$this->{noop}) if $this->{noop};
                d("noop to server 1: <$this->{noop}>");
            }
            $this->{noop} = 'delete';
        }
    } elsif($l=~/^\d{3}\-/o) {
        sendque($cli, $l);
        return;
    } elsif($l=~/^235/o) {
        # check for authentication response
        $Con{$cli}->{relayok} = 1;
        $Con{$cli}->{authenticated}=1;
        d("$Con{$cli}->{ip}: authenticated");
        mlog($cli,"authenticated to $serIP") if $this->{alllog} or $ValidateUserLog>=2;
    } elsif($l=~/^354/o) {
        d('reply - 354');
        $Con{$cli}->{received354} = 1;
    } elsif(uc $Con{$cli}->{lastcmd} eq 'AUTH' && $l=~/^([45]\d\d)/o) {
        d("reply - $1 after AUTH");
        mlog($cli,"warning: SMTP authentication failed on $serIP") if $ConnectionLog;
        my $r = $l;
        $r =~ s/\r|\n//go;
        if ($l =~ /^53[458]/o && !$Con{$cli}->{relayok} && ! &AUTHErrorsOK($cli)) {
            $Con{$cli}->{prepend}="[MaxAUTHErrors]";
            mlog($cli,"max sender authentication errors ($MaxAUTHErrors) exceeded -- dropping connection - after reply: $r from $serIP");
            &NoLoopSyswrite($cli,$l,0);
            done($fh);
            return;
        }
        if($l =~ /^5/o && $MaxErrors && ++$Con{$cli}->{serverErrors} > $MaxErrors) {
            MaxErrorsFailed($cli,
            $l."421 <$myName> closing transmission\r\n",
            "max errors (MaxErrors=$MaxErrors) exceeded -- dropping connection - after reply: $r from $serIP",
            $fh);
            return;
        }
        if ($fakeAUTHsuccess) {
            mlog($cli,"info: faked authentication success for honeypot");
            $Con{$cli}->{fakeAUTHsuccess} = 1;
            pbAdd( $cli, $Con{$cli}->{ip}, 'autValencePB', 'AUTHErrors' );
            $Con{$cli}->{getline} = \&NullFromToData;
            sendque($cli, "235 OK\r\n");
            return;
        }
    } elsif($l=~/^530/o && uc $Con{$cli}->{lastcmd} !~ /AUTH|EHLO|HELO|NOOP|RSET|QUIT/o) {
        d('reply - 530');
        my $r = $l;
        $r =~ s/\r|\n//go;
        if (! $Con{$cli}->{relayok} && ! &AUTHErrorsOK($cli)) {
            $Con{$cli}->{prepend}="[MaxAUTHErrors]";
            mlog($cli,"max sender authentication errors ($MaxAUTHErrors) exceeded -- dropping connection - after reply: $r from $serIP");
            &NoLoopSyswrite($cli,$l,0);
            done($fh);
            return;
        }
        if($MaxErrors && ++$Con{$cli}->{serverErrors} > $MaxErrors) {
            MaxErrorsFailed($cli,
            $l."421 <$myName> closing transmission\r\n",
            "max errors (MaxErrors=$MaxErrors) exceeded -- dropping connection - after reply: $r from $serIP",
            $fh);
            return;
        }
    } elsif($l=~/^(53[458])/o) {
        d("reply - $1");
        mlog($cli,"warning: SMTP authentication failed on $serIP - but 'AUTH' was not the last command") if $ConnectionLog;
    } elsif($l=~/^(50[0-9])/o) {
        d("reply - $1");
        my $r = $l;
        $r =~ s/\r|\n//go;
        mlog($cli,"warning: got reply '$r' from $serIP") if $ConnectionLog;
        if($Con{$cli}->{skipbytes}) {
            d('Resetting skipbytes');
            $Con{$cli}->{skipbytes}=0; # if we got a negative response from XEXCH50 then don't skip anything
        }
        if($MaxErrors && ++$Con{$cli}->{serverErrors} > $MaxErrors) {
            MaxErrorsFailed($cli,
            $l."421 <$myName> closing transmission\r\n",
            "max errors (MaxErrors=$MaxErrors) exceeded -- dropping connection - after reply: $r from $serIP",
            $fh);
            return;
        }
    } elsif($l=~/^550/o) {
        d("reply - 550");
        my $r = $l;
        $r =~ s/\r|\n//go;
        mlog($cli,"warning: got reply '$r' from $serIP") if $ConnectionLog;
        if (!$Con{$cli}->{relayok} && $MaxVRFYErrors && ++$this->{maxVRFYErrors} > $MaxVRFYErrors) {
            $Con{$cli}{prepend}="[MaxVRFYErrors]";
            mlog($cli,"max recipient verification errors ($MaxVRFYErrors) exceeded -- dropping connection - after reply: $r from $serIP");
            $Stats{msgMaxVRFYErrors}++;
            &NoLoopSyswrite($cli,$l."421 <$myName> closing transmission\r\n",0);
            done($fh);
            return;
        }
    } elsif($l=~/^(5\d\d)/o) {
        d("reply - $1");
        my $r = $l;
        $r =~ s/\r|\n//go;
        $Con{$cli}->{deleteMailLog} = "MTA reply $r" if $Con{$cli}->{lastcmd} =~ /data/io;
        mlog($cli,"warning: got reply '$r' from $serIP") if $ConnectionLog && ! $Con{$cli}->{deleteMailLog};
        if ($Con{$cli}->{deleteMailLog}) {
            mlog($cli,"info: got reply '$r' - message is rejeted by the server host $serIP") if $ConnectionLog;
            if ($Con{$cli}->{received354}) {     # the mail is rejected by the MTA while data are received
                sendque($cli, $l);
# sending 5xx after 354 was sent and the dot was not received is a bad behavior of our MTA (only 421 is allowed !)
                $Con{$cli}->{closeafterwrite} = 1;
                unpoll($cli,$readable);
                done2($fh);
            } else {                                    # the DATA command is rejected by the MTA
                $Con{$cli}->{requiredCMD} = 'mail from:|rset|quit';
                $Con{$cli}->{getline} = \&getRequiredCMD;  # set the special handling to keep our state OK
                sendque($cli, $l);
            }
        }
        if($Con{$cli}->{skipbytes}) {
            d('Resetting skipbytes');
            $Con{$cli}->{skipbytes}=0; # if we got a negative response from XEXCH50 then don't skip anything
        }
        if($MaxErrors && ++$Con{$cli}->{serverErrors} > $MaxErrors) {
            $Con{$cli}->{outgoing} = '';
            MaxErrorsFailed($cli,
            $l."421 <$myName> closing transmission\r\n",
            "max errors (MaxErrors=$MaxErrors) exceeded -- dropping connection - after reply: $r from $serIP",
            $fh);
        }
        return;
    } elsif ($l=~/^45[012]/o && $Con{$cli}->{relayok} && $Con{$cli}->{lastcmd} =~ /^(?:ehlo|helo|mail|rcpt)/io) {
        my $r = $l;
        $r =~ s/\r|\n//go;
        mlog($cli,"info: got temp error reply '$r' from server host $serIP for SMTP command '$Con{$cli}->{lastcmd}'") if $ConnectionLog;
        d("got temp error reply '$r' from server host $serIP for SMTP command '$Con{$cli}->{lastcmd}'") unless $ConnectionLog;
    } elsif ($l=~/^(421|45[012])/o) {
        d("reply - $1");
        my $r = $l;
        $r =~ s/\r|\n//go;
        $Con{$cli}->{deleteMailLog} = "MTA reply $r" if $Con{$cli}->{lastcmd} =~ /data/io;
        mlog($cli,"info: got reply '$r' - message is rejeted by the server host $serIP") if $ConnectionLog && $Con{$cli}->{deleteMailLog};
        sendque($cli, $l);
        $Con{$cli}->{closeafterwrite} = 1;
        unpoll($cli,$readable);
        done2($fh);
        return;
    } elsif ($l=~/^221/o) {
        d("reply - 221");
        sendque($cli, $l);
        $Con{$cli}->{closeafterwrite} = 1;
        unpoll($cli,$readable);
        done2($fh);
        return;
    } elsif ($l=~/^250/o and $Con{$cli}->{lastcmd} eq 'SMTPUTF8') {
        d('reply - 250 for SMTPUTF8');
        $Con{$cli}->{SMTPUTF8} = 1;
        mlog($cli,"info: got reply '250 OK' - on SMTPUTF8 command from $serIP") if $ConnectionLog;
        d("info : SMTPUTF8 is used C:$cliIP S:$serIP");
    }

    if ((exists $Con{$cli}->{XCLIENT} || exists $Con{$cli}->{XFORWARD}) &&
         $l=~/^250 /o &&
        ( ($Con{$cli}->{chainMailInSession} > 0 && $Con{$cli}->{lastcmd} =~ /mail from/io) ||
          ($Con{$cli}->{lastcmd} =~ /helo|ehlo/io)
        )
       )
    {
        $this->{Xgetline} = \&reply;
        $this->{Xreply} = $l;
        return if replyX($fh,$cli,$serIP,$cliIP);
        delete $this->{Xgetline};
        delete $this->{Xreply};
    }
    if (exists $this->{fakeTLS} && $l !~ /^250/o) {
        delete $this->{fakeTLS};
        d("info : fakeTLS removed C:$cliIP S:$serIP");
    }
    delete $this->{isTLS};
    delete $Con{$cli}->{isTLS};

    if($Con{$cli}->{sentEHLO} && $l =~ /^250-/o) {
        return;
    }

    # email report/list interface sends messages itself
    return if (defined($Con{$cli}->{reportaddr}));
    return if $l =~ /^(?:\r\n)+$/o;
    sendque($cli, $l);
}
