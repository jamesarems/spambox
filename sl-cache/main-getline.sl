#line 1 "sub main::getline"
package main; sub getline {
    my($fh,$l)=@_;
    d('getline');
    my $this=$Con{$fh};
    my $server=$this->{friend};
    my $friend=$Con{$server};
    my $reply;
    $this->{crashbuf} .= $l if $Con{$fh}->{crashfh};
    d("getline: <$l>");
    if ($friend->{getline} eq \&replyEHLO) {
        $friend->{getline} = \&reply;
    }

    if($l=~/^ *STARTTLS\s*\r\n/io) { # client requests TLS
        $this->{lastcmd} = 'STARTTLS';
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
        mlog($fh,"info: got STARTTLS request from $this->{ip}") if $ConnectionLog;

        if (   $CanUseIOSocketSSL
            && $DoTLS == 2
            && ! $SSLfailed{$this->{ip}}
            && "$fh" !~ /SSL/io
            && ! $this->{gotSTARTTLS}
            && ! &matchIP($this->{ip},'noTLSIP',$fh,0)
            && ! &matchFH($fh,@lsnNoTLSI) )
        {
            $this->{gotSTARTTLS} = 1;
            $this->{isTLS}=1;
            if ($friend->{fakeTLS}) {
                sendque($server, "NOOP\r\n");
            } else {
                sendque($server,$l);   # what is done in case of different server answers ->  reply
            }
        } else {
            NoLoopSyswrite($fh, "502 command not implemented\r\n",0);
        }
        return;
    }

    if (   ! $this->{greetingSent}
        && ! $this->{relayok}
        && &matchFH($fh,@lsnI)
        && ! matchIP($this->{ip},'whiteListedIPs',$fh,0)
        && ! matchIP($this->{ip},'ispip',$fh,0)
        && ! matchIP($this->{ip},'noPB',$fh,0)
        && ! matchIP($this->{ip},'noDelay',$fh,0)
        && ! matchIP($this->{ip},'noBlockingIPs', $fh,0)
        && ! matchIP($this->{ip},'noProcessingIPs',$fh,0)
        && ! matchIP($this->{ip},'noHelo',$fh,0) )
    {
       pbAdd($fh, $this->{ip}, 'etValencePB', "EarlyTalker");
       $this->{prescore} += ${'etValencePB'}[0];
       my $err = "554 5.7.1 Misbehaved SMTP session (EarlyTalker)";
       my $l1 = $l;
       $l1 =~ s/\r|\n//go;
       my $emergency;
       if ($l1 =~ /$NONPRINT/o) {
           $l1 = 'non printable hex data';
           $emergency = 1;
       }
       if ($l =~ /^([^\x00-\x1F\x7F-\xFF]+)/o) {
           $this->{lastcmd} = $1;
           push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
       }
       if (${'etValencePB'}[0] || ${'etValencePB'}[1] || $emergency) {
           mlog($fh, "[EarlyTalker] got '$l1' from the client before the '220 ...' server greeting was sent - rejecting connection", 1) if $SessionLog;
           if ($emergency) {
               mlog($fh, "[EarlyTalker] All connections from IP $this->{ip} will be rejected by assp for the next 15-30 minutes.", 1);
               NoLoopSyswrite($fh,$err."\r\n",0);
               $EmergencyBlock{$this->{ip}} = time;
               done($fh);
               return;
           } else {
               seterror( $fh, $err, 1 );
               return;
           }
       } else {
           mlog($fh, "info: [EarlyTalker] got '$l1' from client before the server greeting '220 ...' was sent - this misbehave is currently ignored, because 'etValencePB' is set to zero", 1) if $SessionLog >= 2 && ! $this->{relayok};
           $this->{greetingSent} = 1;
       }
    } elsif (! $this->{greetingSent}) {
       $this->{greetingSent} = 1;
       mlog($fh, "info: [EarlyTalker] client has sent data before the server greeting '220 ...' was sent - this misbehave is currently ignored for this IP", 1) if $SessionLog >= 2 && ! $this->{relayok};
       mlog($fh, "info: [EarlyTalker] client has sent data before the server greeting '220 ...' was sent - this misbehave is currently ignored, because a relayed/local connection is in use", 1) if $SessionLog >= 2 && $this->{relayok};
    } else {
       $this->{greetingSent} = 1;
    }

    if($l=~/^( *(helo|ehlo) *[<>,;\"\'\(\)\s]*([^<>,;\"\'\(\)\s]*))/io) {
        $this->{lastcmd} = $2;
        my $helo = $3;
        my $fhelo = $this->{orghelo} = $1;
        if (! $helo) {
            $helo = 'localhost';
            $fhelo = $this->{orghelo} = $this->{lastcmd} . ' ' . $helo;
            if ($DoInvalidFormatHelo) {
                pbWhiteDelete( $fh , $this->{ip} );
                pbAdd( $fh, $this->{ip}, 'ihValencePB', "InvalidHELO" );
                $this->{prescore} += ${'ihValencePB'}[0];
                $this->{invalidhelofound} = 1;
                if ($ValidateSenderLog) {
                    my $e = $l;
                    $e =~ s/[\r\n]//go;
                    my $v = $e;
                    $v =~ s/^ *(?:helo|ehlo) *[<>,;\"\'\(\)\s]*//oi;
                    $v = $v ? 'without an evadable ('.$v.')' : 'without any';
                    $e = ($ValidateSenderLog > 1) ? " ($e)" : '';
                    mlog($fh,'got '.uc($this->{lastcmd})." $v host or domain name$e");
                }
            }
        }
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
        if ($l=~/^ *ehlo/io) {
           if ($friend->{noop} ne 'delete') {
               $friend->{getline} = \&reply;
           } else {
               delete $friend->{noop};
           }
           delete $this->{sentEHLO};
           delete $friend->{answertToHELO};
        }
        if (($DoTLS == 2 || ! $DoTLS) &&
            $sendEHLO &&
            $l =~ s/^ *helo/ehlo/io
        ) {
            $this->{lastcmd} = 'ehlo';
            push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
            $fhelo =~ s/^ *helo/ehlo/io;
            mlog($fh,"info: sending EHLO instead of HELO to " . $server->peerhost()) if $ConnectionLog;
            $this->{sentEHLO} = 1;
            $friend->{getline} = \&replyEHLO;
        }
        my $helo2 = $this->{helo} = $helo;
        $helo=~s/(\W)/\\\$1/go;
        my $ptr;
        if (! $this->{relayok}) {
            $ptr = $this->{PTR};
            if (! $ptr && $this->{ip} !~ /$IPloopback/io) {
                $this->{PTR} = $ptr = [split( / /o, $PTRCache{$this->{ip}} )]->[2];
                if (! $ptr) {
                    &sigoffTry(__LINE__);
                    $this->{PTR} = $ptr = getRRData($this->{ip},'PTR');
                    &sigonTry(__LINE__);
                    if ($ptr) {
                        PTRCacheAdd($this->{ip},0,$ptr)
                    } elsif ($lastDNSerror eq 'NXDOMAIN' || $lastDNSerror eq 'NOERROR') {
                        PTRCacheAdd($this->{ip},1,$ptr);
                    }
                }
            }
            $this->{PTR} = $ptr = $localhostname || 'localhost' if (! $ptr && $this->{ip} =~ /$IPloopback/io);
        } elsif ($HideIPandHelo) {
            my %fake;
            $fake{$1} = $2 while (lc $HideIPandHelo =~ /(ip|helo)\s*=\s*(\S+)/iog);
            $helo2 = $fake{helo} if exists $fake{helo};
            $this->{rcvd} =~ s/\[$IPRe\]/[$fake{ip}]/o if exists $fake{ip};
        }
        $ptr =~ s/\.$//o;
        $this->{PTR} =~ s/\.$//o;
        if ($ptr) {
            $this->{rcvd}=~s/=host/$ptr/o;
        } else {
            $this->{rcvd}=~s/=host/unknown/o;
        }
        $this->{rcvd}=~s/=\)/=$helo2\)/o;
        my $prot = ("$fh" =~ /SSL/io) ? 'SMTPS' : 'SMTP';
        $prot = 'E' . $prot if lc($this->{orghelo}) eq 'ehlo';
        $this->{rcvd} =~ s/\*SMTP\*/$prot/o;
        $this->{rcvd} = &headerWrap($this->{rcvd}); # wrap long lines
        if ($this->{chainMailInSession} < 0) {  # there was no 'MAIL FROM' seen before
            $this->{firstrcvd} = $this->{rcvd};
            $this->{firstrcvd} =~ s/;\s*([^;]+)\r\n$/\r\n/os;
        }
        if ($myHelo) {
            my ($mhi,$mho) = split(/\s*\|\s*/o , $myHelo, 2);
            $mhi =~ s/^\s+//o;
            $mho =~ s/\s+$//o;
            my $mh = $this->{relayok} ? $mho : $mhi;
            $mh =~ s/IP/$this->{ip}/go;
            $mh =~ s/MYNAME/$myName/go;
            $mh =~ s/FQDN/$localhostname/go;
            $mh =~ s/SENDERHELO/$this->{helo}/go;
            if ($mh =~ /\S/) {
                $l = $fhelo = "$this->{lastcmd} $mh";
                $l .= "\r\n";
            }
        }
        $this->{fullhelo} = $fhelo if (lc($this->{lastcmd}) eq 'ehlo');

    } elsif($l=~/^(\s*AUTH([^\r\n]*))\r?\n/io) {
        my $ffr = $1;
        my $authmeth = $2;

        if ( ! $this->{relayok} && $this->{DisableAUTH} )
        {
            $this->{lastcmd} = 'AUTH';
            push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
            $this->{prepend}="[unsupported_$this->{lastcmd}]";
            mlog($fh,"$this->{lastcmd} not allowed");
            if($MaxErrors && ++$this->{serverErrors} > $MaxErrors) {
                MaxErrorsFailed($fh,
                "502 $this->{lastcmd} not supported\r\n421 <$myName> closing transmission\r\n",
                "max errors (MaxErrors=$MaxErrors) exceeded -- dropping connection after $this->{lastcmd}");
                return;
            }
            sendque($fh, "502 $this->{lastcmd} not supported\r\n");
            return;
        }

        my %posmeth = (0 => undef, 1 => 'PLAIN',2 => 'LOGIN',3 => 'PLAIN|LOGIN',4 => '.+');
        my $methCheck = $posmeth{$AUTHrequireTLS};
        if ($methCheck && "$fh" !~ /SSL/io && $this->{ip} !~ /$IPprivate/o && $authmeth =~ /$methCheck/i)
        {
            $this->{lastcmd} = 'AUTH';
            push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
            $this->{prepend}="[unsupported_$this->{lastcmd}_encryption_required]";
            mlog($fh,"$this->{lastcmd} encryption required for requested authentication mechanism $authmeth");
            if($MaxErrors && ++$this->{serverErrors} > $MaxErrors) {
                MaxErrorsFailed($fh,
                "538 5.7.11 encryption required for requested authentication mechanism\r\n421 <$myName> closing transmission\r\n",
                "max errors (MaxErrors=$MaxErrors) exceeded -- dropping connection after $this->{lastcmd}");
                return;
            }
            sendque($fh, "538 5.7.11 encryption required for requested authentication mechanism\r\n");
            return;
        }

        my $ip = &ipNetwork( $this->{ip}, 1);
        if ($MaxAUTHErrors && $AUTHErrors{$ip} >= $MaxAUTHErrors) {
            $this->{prepend}='[MaxAUTHErrors]';
            NoLoopSyswrite($fh,"521 $myName does not accept mail - closing transmission - too many previouse AUTH errors from network $ip\r\n",0);
            mlog($fh,"too many ($AUTHErrors{$ip}) AUTH errors from network $ip") if $ConnectionLog;
            if (! matchIP($this->{ip},'noPB',0,1)) {
                pbAdd( $fh, $this->{ip}, 'autValencePB', 'AUTHErrors' );
                $this->{prescore} += ${'autValencePB'}[0];
            }
            $AUTHErrors{$ip}++;
            done($fh);
            return;
        }

        if ($CanUseIOSocketSSL &&
            $DoTLS == 2 &&
            ! $SSLfailed{$this->{ip}} &&
            $friend->{donotfakeTLS} &&
            ! $this->{gotSTARTTLS} &&
            ! $this->{TLSqueue} &&
            "$server" !~ /SSL/io &&
            ! &matchIP($this->{ip},'noTLSIP',$fh,1) &&
            ! &matchFH($fh,@lsnNoTLSI)
        ) {
            NoLoopSyswrite($server,"STARTTLS\r\n",0);
            $friend->{getline} = \&replyTLS;
            $this->{TLSqueue} = $ffr;
            mlog($fh,"info: injected STARTTLS request to " . $server->peerhost()) if $ConnectionLog;
            return;
        }
        $authmeth =~ s/^\s+//o;
        $authmeth =~ s/\s+$//o;
        if ($authmeth =~ /(plain|login)\s*(.*)/io) {
            $authmeth = lc $1;
            my $authstr = base64decode($2);
            mlog($fh,"info: authentication - $authmeth is used") if $ValidateUserLog;
            if ($authmeth eq 'plain' and $authstr) {
                ($this->{userauth}{foruser},$this->{userauth}{user},$this->{userauth}{pass}) = split(/ |\0/so,$authstr);
                $this->{userauth}{stepcount} = 0;
                $this->{userauth}{authmeth} = 'plain';
                if ($AUTHLogUser) {
                    my $tolog = "info: authentication (PLAIN) realms - foruser:$this->{userauth}{foruser}, user:$this->{userauth}{user}";
                    $tolog .= ", pass:$this->{userauth}{pass}" if $AUTHLogPWD;
                    mlog($fh,$tolog);
                }
            } elsif ($authmeth eq 'plain' && ! $authstr) {
                $this->{userauth}{stepcount} = 1;
                $this->{userauth}{authmeth} = 'plain';
            } elsif ($authmeth eq 'login' && $authstr) {
                $this->{userauth}{user} = $authstr;
                $this->{userauth}{stepcount} = 1;
                $this->{userauth}{authmeth} = 'login';
            } else {
                $this->{userauth}{stepcount} = 2;
                $this->{userauth}{authmeth} = 'login';
            }
        }
        $this->{lastcmd} = 'AUTH';
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
        $this->{doneAuthToRelay} = 1;
        sendque($server,$l);
        return;

    } elsif ($this->{userauth}{stepcount}) {
        if ($this->{userauth}{authmeth} eq 'plain') {
            $this->{userauth}{stepcount} = 0;
            $l =~ /([^\r\n]*)\r\n/o;
            my $authstr = base64decode($1);
            ($this->{userauth}{foruser},$this->{userauth}{user},$this->{userauth}{pass}) = split(/ |\0/o,$authstr);
            if ($AUTHLogUser) {
                my $tolog = "info: authentication (PLAIN) realms - foruser:$this->{userauth}{foruser}, user:$this->{userauth}{user}";
                $tolog .= ", pass:$this->{userauth}{pass}" if $AUTHLogPWD;
                mlog($fh,$tolog);
            }
            sendque($server,$l);
            return;
        } elsif ($this->{userauth}{stepcount} == 2) {
            $this->{userauth}{stepcount} = 1;
            $l =~ /([^\r\n]*)\r\n/o;
            $this->{userauth}{user} = base64decode($1);
            sendque($server,$l);
            return;
        } else {
            $this->{userauth}{stepcount} = 0;
            $l =~ /([^\r\n]*)\r\n/o;
            $this->{userauth}{pass} = base64decode($1);
            if ($AUTHLogUser) {
                my $tolog = "info: authentication (LOGIN) realms - user:$this->{userauth}{user}";
                $tolog .= ", pass:$this->{userauth}{pass}" if $AUTHLogPWD;
                mlog($fh,$tolog);
            }
            sendque($server,$l);
            return;
        }

    } elsif (&syncCanSync() && $enableCFGShare && $isShareSlave && $l=~/^ *SPAMBOXSYNCCONFIG\s*([^\r\n]+)\r\n/o ) {
        my $pass = $1;
        mlog(0,"info: got SPAMBOXSYNCCONFIG request from $this->{ip}") if $ConnectionLog >=2;
        $this->{lastcmd} = 'SPAMBOXSYNCCONFIG';
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
        my @tservers = split(/\|/o, $syncServer);
        my @servers;
        my %se;
        foreach (@tservers) {
            s/\s//go;
            s/\:\d+$//o;
            if ($_ =~ /^$IPRe$/o) {
                push(@servers, $_);
                $se{$_} = $_;
                next;
            }
            my $ip = eval{inet_ntoa( scalar( gethostbyname($_) ) );};
            if ($ip) {
                push(@servers, $ip);
                $se{$ip} = $_;
                next;
            } else {
                mlog(0,"syncCFG: error - unable to resolve ip for syncServer name $_ - $@");
            }
        }
        if (! @servers || ! (@servers = grep { $this->{ip} eq $_ } @servers )) {
            NoLoopSyswrite( $fh, "502 $this->{lastcmd} not implemented $this->{ip} - @servers\r\n" ,0);
            mlog($fh,"syncCFG: error - got 'SPAMBOXSYNCCONFIG' command from wrong ip $this->{ip}");
            done($fh);
            return;
        }
        if (Digest::MD5::md5_base64($syncCFGPass) ne $pass) {
            NoLoopSyswrite( $fh, "500 $this->{lastcmd} wrong authentication - check you configuration\r\n" ,0);
            mlog($fh,"syncCFG: error - got wrong password in 'SPAMBOXSYNCCONFIG' command from $this->{ip}");
            done($fh);
            return;
        }
        done2($server);
        my $ip = $this->{ip};
        $this->{syncServer} = $se{$ip};
        $this->{getline} = \&syncRCVData;
        NoLoopSyswrite($fh,"250 OK start the config sync\r\n",0);
        return;
    } elsif ($l=~/^ *SPAMBOXSYNCCONFIG\s*([^\r\n]+)?\r\n/o ) {
        my $pass = $1;
        mlog(0,"info: got SPAMBOXSYNCCONFIG request from $this->{ip}") if $ConnectionLog >=2;
        $this->{lastcmd} = 'SPAMBOXSYNCCONFIG';
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
        if (Digest::MD5::md5_base64($syncCFGPass) ne $pass) {
            NoLoopSyswrite( $fh, "502 $this->{lastcmd} not implemented\r\n",0 );
            mlog($fh,"syncCFG: error - got syncCFG request, but this is not an 'isShareSlave' and got wrong password in 'SPAMBOXSYNCCONFIG' command from $this->{ip}");
            done($fh);
            return;
        }
        NoLoopSyswrite( $fh, "500 $this->{lastcmd} - sync peer $this->{ip} is not registered on $myName or this is not an isShareSlave\r\n",0 );
        mlog($fh,"syncCFG: error - got 'SPAMBOXSYNCCONFIG' command from ip $this->{ip} - the request will be ignored - check your configuration");
        done($fh);
        return;

    } elsif ($l=~/^ *($notAllowedSMTP)/io) {
        $this->{lastcmd} = $1;
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
        $this->{prepend}="[unsupported_$this->{lastcmd}]";
        mlog($fh,"$this->{lastcmd} not allowed");
        if(! $this->{relayok} && $MaxErrors && ++$this->{serverErrors} > $MaxErrors) {
            MaxErrorsFailed($fh,
            "502 $this->{lastcmd} not supported\r\n421 <$myName> closing transmission\r\n",
            "max errors (MaxErrors=$MaxErrors) exceeded -- dropping connection after $this->{lastcmd}");
            return;
        }
        sendque($fh, "502 $this->{lastcmd} not supported\r\n");
        return;
    } elsif ($l=~/(mail from:\s*<?($EmailAdrRe\@$EmailDomainRe|\s*)>?)/io) {
        my $fr=$2;
        my $ffr = $1;

        if ( ! $this->{relayok} && $this->{DisableAUTH} && $l =~ /\sAUTH=/io )
        {
            $this->{lastcmd} = 'AUTH';
            push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
            $this->{prepend}="[unsupported_$this->{lastcmd}]";
            mlog($fh,"$this->{lastcmd} not allowed");
            if($MaxErrors && ++$this->{serverErrors} > $MaxErrors) {
                MaxErrorsFailed($fh,
                "502 $this->{lastcmd} not supported\r\n421 <$myName> closing transmission\r\n",
                "max errors (MaxErrors=$MaxErrors) exceeded -- dropping connection after $this->{lastcmd}");
                return;
            }
            sendque($fh, "502 $this->{lastcmd} not supported\r\n");
            return;
        }

        if ($CanUseIOSocketSSL &&
            $DoTLS == 2 &&
            ! $SSLfailed{$this->{ip}} &&
            $friend->{donotfakeTLS} &&
            ! $this->{gotSTARTTLS} &&
            ! $this->{TLSqueue} &&
            "$server" !~ /SSL/io &&
            ! &matchIP($this->{ip},'noTLSIP',$fh,1) &&
            ! &matchFH($fh,@lsnNoTLSI)
        ) {
            NoLoopSyswrite($server,"STARTTLS\r\n",0);
            $friend->{getline} = \&replyTLS;
            $this->{TLSqueue} = $ffr;
            mlog($fh,"info: injected STARTTLS request to " . $server->peerhost()) if $ConnectionLog;
            return;
        }

        stateReset($fh); # reset everything
        $this->{lastcmd} = 'MAIL FROM';
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
        if($EnforceAuth && &matchFH($fh,@lsn2I) && ! $this->{authenticated} && ! $this->{DisableAUTH} && ($l !~ /\sAUTH=[^\r\n\s<>]+/io || $l =~ /\sAUTH=<>/io)) {
            NoLoopSyswrite($fh,"530 5.7.0 Authentication required\r\n",0);
            mlog($fh,"$fr submited without previouse or included AUTH - 'EnforceAuth' is set to 'ON' for 'listenPort2'",1);
            done($fh);
            return;
        }

# authentication on relayserver
        if ($CanUseAuthenSASL &&
            ! $this->{doneAuthToRelay} &&
            $this->{relayok} &&
            scalar keys %{$this->{authmethodes}} &&
            $relayAuthUser &&
            $relayAuthPass
           )
        {
            $this->{doneAuthToRelay} = 1;
            $this->{sendAfterAuth} = $l;
            foreach ('PLAIN','LOGIN','CRAM-MD5','DIGEST-MD5') {
                $this->{AUTHmechanism} = $_ if exists $this->{authmethodes}->{$_};
            }
            $this->{AUTHmechanism} = 'PLAIN' unless $this->{AUTHmechanism};
            mlog($fh,"info: starting authentication - AUTH $this->{AUTHmechanism}") if $SessionLog >= 2;
            $this->{AUTHclient} =
                Authen::SASL->new(
                                    mechanism => $this->{AUTHmechanism},
                                    callback  => {
                                        user     => $relayAuthUser,
                                        pass     => $relayAuthPass,
                                        authname => $relayAuthUser
                                    },
                                    debug => $ThreadDebug
                )->client_new('smtp');
            @{$this->{AUTHClient}} = ();
            my $str = $this->{AUTHclient}->client_start;
            push (@{$this->{AUTHClient}}, MIME::Base64::encode_base64($str, ''))
                 if defined $str and length $str;
            NoLoopSyswrite($server,'AUTH ' . $this->{AUTHclient}->mechanism . "\r\n",0);
            $friend->{getline} = \&replyAUTH;

            return;
        }
# end authentication on relayserver

        $this->{relayok} = 1 if ( $EnforceAuth && &matchFH($fh,@lsn2I) );

        $this->{mailfrom}=$fr;
        $this->{mailfrom} =~ s/\s//go;
        
        # BATV stuff  for mail from
        if ($this->{relayok}) {               # it's outgoing mail
            if ($DoBATV && $this->{mailfrom}) {         # if there is a sender address and BATV enabled
                $this->{mailfrom} = &batv_mail_out($fh,$this->{mailfrom});   # tag mailfrom
                $l =~ s/$fr/$this->{mailfrom}/i;        # replace orig sender address with taged address
            }
        } else {                             # it's incoming mail
            $this->{mailfrom} = batv_remove_tag($fh,$this->{mailfrom},'BATVfrom') if ($removeBATVTag); # remove possible BATV-Tag from sender address  - if removed orig recipient is strored in ->{BATVfrom}
            mlog($fh,"BATV-Tag removed from sender address $fr") if ($BATVLog && lc($fr) ne lc($this->{mailfrom}));
            if (lc($this->{mailfrom}) ne lc($fr) && $remindBATVTag) {   # if Tag was removed
                 if (! &localmail($this->{mailfrom})) {
                     $BATVTag{lc($this->{mailfrom})} = $fr;  # store sender address and Tag pair in Cache if it's not local mail
                     mlog($fh,"info: BATVTag $fr stored in Cache for " .lc($this->{mailfrom})) if $BATVLog >= 2;
                 }
            }
        }
        # end BATV  for mail from

        my $t=time;
        my $mf = batv_remove_tag(0,lc($this->{mailfrom}),'');
        my $mfd;
        $mfd = $1 if $mf=~/\@(.*)/o;
        my $mfdd;
        $mfdd = $1 if $mf=~/(\@.*)/o;

        my $alldd = "$wildcardUser$mfdd";
        my $defaultalldd = "*$mfdd";

        if($l=~/SIZE=(\d*)\s/io) {
            my $size = $1;
            $this->{SIZE}=$size;
            mlog($fh,"info: found message size announcement: " . &formatNumDataSize($size)) if $SessionLog;

            if ( ($this->{relayok} && $maxSize
                    && ( $size > $maxSize )) or (!$this->{relayok} && $maxSizeExternal
                    && ( $size > $maxSizeExternal )))
            {
                my $max = $this->{relayok} ? $maxSize : $maxSizeExternal;
                my $err = "552 message exceeds MAXSIZE byte (size)";
                mlog( $fh, "error: message exceeds maxSize $max bytes (size)!" );
                $err = $maxSizeError if ($maxSizeError);
                $err =~ s/MAXSIZE/$max/go;
                seterror( $fh, $err, 1 );
                return;
            }

            if ($this->{relayok}) {
                if ($npSizeOut && $size > $npSizeOut) {
                    $this->{ismaxsize}=1;
                    if (localmail($mf)) {
                        $this->{noprocessing} = 1;
                        mlog($fh,"message proxied without processing - message size ($size) is above $npSizeOut (npSizeOut).",1);
                        $this->{passingreason} = "noProcessing - message size ($size) is above $npSizeOut (npSizeOut)";
                    }
                }
            } else {
                if ($npSize && $size > $npSize) {
                    $this->{ismaxsize}=1 ;
                }
            }
        }
        if($l=~/ AUTH=.+/io) {
            $this->{doneAuthToRelay} = 1;
            $this->{lastcmd} = 'AUTH'; # set this for subs reply check the 235
            push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
        }

########################################################### !relayok ############

        $this->{senderok} = 1 if ( matchSL( $mf, 'EmailSenderOK' ) );
        $this->{senderok} = 2 if ( matchSL( $mf, 'EmailSenderNotOK' ) ) ;
        $this->{senderok} = 3 if ( matchSL( $mf, 'EmailSenderIgnore' ) ) ;

        $this->{nocollect} ||= matchSL( $mf, 'noCollecting' );

        if ($this->{mailfrom}=~/$BSRE/) {
            $this->{prepend} = '[isbounce]';
            mlog($fh,"bounce message detected");
            $this->{isbounce}=1;
            $this->{red}="bounces are not collected" if ($DoNotCollectBounces);
        }

        if (!$this->{relayok}) {

            if ($allLogRe
                && (   $mf =~ /$allLogReRE/
                    || $this->{ip}   =~ /$allLogReRE/
                    || $this->{helo} =~ /$allLogReRE/)
              ) {
               $this->{alllog}=1;
            }
            if(!$this->{contentonly} && $contentOnlyRe && ($mf=~/($contentOnlyReRE)/  || $this->{ip}=~/($contentOnlyReRE)/  || $this->{helo}=~/($contentOnlyReRE)/)){
                mlogRe($fh,($1||$2),'contentOnlyRe','ContentOnly');
                pbBlackDelete($fh,$this->{ip});
                $this->{contentonly}=1;
                $this->{ispip}=1;
            }

            if ($Con{$server}->{relayok} && $WhitelistAuth){
                $this->{whitelisted}=1;
                $this->{passingreason} = ": authenticated";
            }
            $this->{red} = "$mf in RedList"
              if ( $Redlist{"$alldd"}
                || $Redlist{"$defaultalldd"}
                || $Redlist{"$mf"} );

            if (! $this->{whitelisted} && &Whitelist($mf) && ! localmail($mf)) {
                &Whitelist($mf,undef,'add');
                $this->{whitelisted}=1;
                $this->{passingreason} = "whitelistdb" if !$this->{passingreason};
            }
            if (! $this->{whitelisted} && $whiteListedDomains && matchRE([$mf],'whiteListedDomains')) {
                $this->{passingreason} = "whiteListedDomains '$lastREmatch'";
                $this->{whitelisted}=1;
            }
            if (! $this->{whitelisted} && $whiteRe && ($this->{helo}=~/($whiteReRE)/ || $this->{ip}=~/($whiteReRE)/ || $mf=~/($whiteReRE)/) ) {
                mlogRe($fh,($1||$2),'whiteRe','whitelisting') ;
                $this->{whitelisted}=1;
                $this->{passingreason} = "whiteRe '$1'";
            }
            if (! $this->{whitelisted} && (&Whitelist($mf) || &Whitelist($defaultalldd)) && ! localmail($mf)) {
                mlogRe($fh,$mfdd,'wildcardUser','whitelisting') ;
                $this->{whitelisted}=1;
                &Whitelist($alldd,undef,'add');
                &Whitelist($defaultalldd,undef,'add');
                &Whitelist($mfdd,undef,'add');
                $this->{passingreason} = "wildcardUser";
            }
            $this->{red}="$mf in RedList" if ($Redlist{"$alldd"} || $Redlist{"$defaultalldd"} || $Redlist{"$mf"});
            my $ret = matchIP( $this->{ip}, 'whiteListedIPs', $fh ,0);
            if (  $whiteListedIPs && $ret )
            {
                $this->{whitelisted}   = 1;
                $this->{passingreason} = "whiteListedIPs '$ret'";
            }

            $this->{ispip}=1 		if ( matchIP($this->{ip},'ispip',$fh,0));
            $this->{nopb}=1 		if ( matchIP($this->{ip},'noPB',$fh,0));
            $this->{nopbwhite}=1 	if ( matchIP( $this->{ip}, 'noPBwhite', $fh ,0) );
            $this->{rwlok} =
            $this->{pbwhite}=1 		if pbWhiteFind($this->{ip});
            $this->{nohelo}=1 		if ( matchIP($this->{ip},'noHelo',$fh,0));

            $this->{nodelay} ||= 1 		if matchIP($this->{ip},'noDelay',$fh,0) or matchSL($this->{mailfrom},'noDelayAddresses');
            $this->{acceptall} ||= 1	if matchIP($this->{ip},'acceptAllMail',$fh,0);
            $this->{noblockingips} ||= 1  if matchIP( $this->{ip}, 'noBlockingIPs', $fh ,0);

            if (! $this->{noprocessing} && $noProcessing && $mf=~/($NPREL)/) {
                mlogRe($fh,$1,'noProcessing','noprocessing');
                $this->{noprocessing} = 1;
                $this->{passingreason} = 'noProcessing';
            }
            if (! $this->{noprocessing} && matchSL( $mf, 'noProcessingFrom' )) {
                $this->{noprocessing} = 1;
                $this->{passingreason} = 'noProcessingFrom';
            }
            if (! $this->{noprocessing} && $noProcessingDomains && $mf=~/($NPDRE)/) {
                mlogRe($fh,$1,'noProcessingDomains','noprocessing') ;
                $this->{noprocessing} = 1;
                $this->{passingreason} = "noProcessingDomain '$1'";
            }
            if (! $this->{noprocessing} && matchIP($this->{ip},'noProcessingIPs',$fh,0)) {
                $this->{noprocessing} = 1;
                $this->{passingreason} = "noProcessingIPs";
            }
            if ($this->{noprocessing} & 1) {
                pbBlackDelete($fh,$this->{ip});
                pbWhiteAdd($fh,$this->{ip},"NoProcessing");
            }

            if (! $this->{noprocessing} && $this->{ismaxsize}) {
                if (! localmail($mf)) {
                    mlog($fh,"message proxied without processing - message size ($this->{SIZE}) is above $npSize (npSize).",1);
                    $this->{noprocessing} = 2;
                    $this->{passingreason} = "noProcessing - message size ($this->{SIZE}) is above $npSize (npSize)";
                }
            }

            if ($this->{whitelisted}) {
                pbBlackDelete($fh,$this->{ip});
                pbWhiteAdd($fh,$this->{ip},"Whitelisted");
            }

            my $ip=$this->{ip};

            my $myip = &ipNetwork( $ip, $PenaltyUseNetblocks );

            unless (   ($this->{whitelisted} && !$ExtremeWL)
                    || ($this->{noprocessing} eq '1' && !$ExtremeNP) )
            {
                my $myextreme;
                if ( $PenaltyExtreme && [split( ' ', $PBBlack{$myip} )]->[3] >= $PenaltyExtreme ) {   # totalscore
                    $myextreme = $myip;
                }

                if (   $DoPenaltyExtremeSMTP
                    && $myextreme
                    && ! matchIP( $ip, 'noPB',            0, 1 )
                    && ! matchIP( $ip, 'noExtremePB',     0, 1 )
                    && ! matchSL( $mf, 'noExtremePBAddresses' )
                    && (! matchIP( $ip, 'noProcessingIPs', 0, 1 ) ||
                       ($ExtremeNP && matchIP( $ip, 'noProcessingIPs', 0, 1 )))
                    && (! matchIP( $ip, 'whiteListedIPs',  0, 1 ) ||
                       ($ExtremeWL && matchIP( $ip, 'whiteListedIPs', 0, 1 )))
                    && ! matchIP( $ip, 'noDelay',         0, 1 )
                    && ! matchIP( $ip, 'ispip',           0, 1 )
                    && ! matchIP( $ip, 'acceptAllMail',   0, 1 )
                    && ! matchIP( $ip, 'noBlockingIPs',   0, 1 )
                    && ! pbWhiteFind($ip) )
                {
                    if ( $DoPenaltyExtremeSMTP == 1 ) {
                        $this->{prepend} = "[denyExtreme]";
                        mlog( $fh, "connection from $ip denied by PenaltyBox Extreme '$myip'" ) if $PenaltyExtremeLog;
                        $Stats{smtpConnDenied}++;
                        seterror( $fh, "554 5.7.1 Extreme Bad IP Profile", 1 );
                        d('getline - PenaltyBox Extreme');
                        return;
                    }
                    if ( $DoPenaltyExtremeSMTP == 2 ) {
                        $this->{prepend} = "[denyExtreme][monitoring]";
                        mlog( $fh, "monitoring: connection from $ip would be denied by PenaltyBox Extreme '$myip'" )
                          if $PenaltyExtremeLog >= 2;
                    }
                }
            }

            if ( ! $this->{ispip} && "$fh" =~ /SSL/io && (${'tlsValencePB'}[0] || ${'tlsValencePB'}[1])) {
                $this->{messagereason} = 'SSL-TLS-connection-OK';
                pbAdd( $fh, $this->{ip}, 'tlsValencePB', 'SSL-TLS-connection-OK' );
            }

            $this->{pbblack} = 1 if pbBlackFind($this->{ip});

            if (   $DoDomainIP
                && $this->{pbblack}
                && !$this->{pbwhite}
                && $maxSMTPdomainIP
                && $mfd
                && !$this->{nopb}
                && !$this->{whitelisted}
                && !$this->{rwlok}
                && $this->{noprocessing} ne '1'
                && !$this->{ispip}
                && !$this->{acceptall}
                && !$this->{contentonly}
                && !$this->{noblockingips}
                && (! $ValidateSPF || ($SPFCacheInterval && $SPFCacheObject && [&SPFCacheFind($this->{ip},$mfd)]->[1] ne 'pass'))
                && (!$maxSMTPdomainIPWL || ($maxSMTPdomainIPWL &&  $mfd!~/($IPDWLDRE)/))
               )
            {
                $this->{doneDoDomainIP} = 1;
                my $myip=&ipNetwork($this->{ip}, $DelayUseNetblocks) . '.';
                if ((time - $SMTPdomainIPTriesExpiration{$mfd}) > $maxSMTPdomainIPExpiration) {
                    $SMTPdomainIPTries{$mfd} = 1;
                    $SMTPdomainIPTriesExpiration{$mfd} = time;
                    $myip =~ s/\./\\\./go;
                    $SMTPdomainIP{$mfd} = $myip;
                } elsif ($myip !~ /^(?:$SMTPdomainIP{$mfd})$/) {
                    $SMTPdomainIP{$mfd} .= '|' if $SMTPdomainIP{$mfd};
                    $myip =~ s/\./\\\./go;
                    $SMTPdomainIP{$mfd} .= $myip;
                    $SMTPdomainIPTriesExpiration{$mfd} = time if $SMTPdomainIPTries{$mfd}==1;
                    $SMTPdomainIPTries{$mfd}++;
                }
                my $tlit = &tlit($DoDomainIP);
                $tlit = "[testmode]"   if $allTestMode && $DoDomainIP == 1 || $DoDomainIP == 4;
                my $DoDomainIP = $DoDomainIP;
                $DoDomainIP = 3 if $allTestMode && $DoDomainIP == 1 || $DoDomainIP == 4;
                if ( exists $SMTPdomainIPTries{$mfd} && $SMTPdomainIPTries{$mfd} > $maxSMTPdomainIP) {
                    my $doSPF = ($CanUseSPF && $ValidateSPF) || ($CanUseSPF2 && $ValidateSPF && $SPF2);
                    if (   $doSPF
                        && $enableSPFbackground
                        && $SPFCacheInterval
                        && $SPFCacheObject
                        && $mf
                        && (my ($helo) = $this->{orghelo} =~ /^ *(?:helo|ehlo) [<>,;\"\'\(\)\s]*([^<>,;\"\'\(\)\s]+)/io)
                        && ! &SPFCacheFind($this->{ip},$mfd)
                       )
                    {
                        cmdToThread('SPFbg',"$this->{ip} $mf $helo");
                    }
                    $this->{prepend} = "[IPperDomain]";
                    $this->{messagereason} = "'$mfdd' passed limit($maxSMTPdomainIP) of ips per domain";

                    mlog( $fh, "$tlit $this->{messagereason}")
                      if (  ($SessionLog && $SMTPdomainIPTries{$mfd} == $maxSMTPdomainIP + 1)
                          ||($SessionLog >= 2 && $SMTPdomainIPTries{$mfd} > $maxSMTPdomainIP + 1));

                    pbAdd( $fh, $this->{ip}, 'idValencePB', "LimitingIPDomain" ) if $DoDomainIP != 2;
                    if ( $DoDomainIP == 1 ) {
                        $Stats{smtpConnDomainIP}++;
                        seterror( $fh, "554 5.7.1 too many different IP's for domain '$mfdd'", 1 );
                        return;
                    }
                }
            }

            # ip connection limiting per timeframe
            if (   $DoFrequencyIP
                && $this->{pbblack}
                && !$this->{pbwhite}
                && $maxSMTPipConnects
                && !$this->{nopb}
                && !$this->{whitelisted}
                && !$this->{rwlok}
                && $this->{noprocessing} ne '1'
                && !$this->{ispip}
                && !$this->{acceptall}
                && !$this->{contentonly}
                && !$this->{noblockingips}
               )
            {
                my $ConIp550 = $this->{ip};
                $this->{doneDoFrequencyIP} = $ConIp550;

       # If the IP address has tried to connect previously, check it's frequency
                if ( $IPNumTries{$ConIp550} ) {
                    $IPNumTries{$ConIp550}++;

              # If the last connect time is past expiration, reset the counters.
              # If it has not expired, but is outside of frequency duration and
              # below the maximum session limit, reset the counters. If it is
              # within duration
                    if (((time - $IPNumTriesExpiration{$ConIp550}) > $maxSMTPipExpiration)  || ((time - $IPNumTriesDuration{$ConIp550}) > $maxSMTPipDuration) && ($IPNumTries{$ConIp550} < $maxSMTPipConnects)) {
                        $IPNumTries{$ConIp550} = 1;
                        $IPNumTriesDuration{$ConIp550} = time;
                        $IPNumTriesExpiration{$ConIp550} = time;
                    }
                } else {
                    $IPNumTries{$ConIp550} = 1;
                    $IPNumTriesDuration{$ConIp550} = time;
                    $IPNumTriesExpiration{$ConIp550} = time;

                }
                my $tlit = &tlit($DoFrequencyIP);
                $tlit = "[testmode]"   if $allTestMode && $DoFrequencyIP == 1 || $DoFrequencyIP == 4;

                my $DoFrequencyIP = $DoFrequencyIP;
                $DoFrequencyIP = 3 if $allTestMode && $DoFrequencyIP == 1 || $DoFrequencyIP == 4;

                if ( $IPNumTries{$ConIp550} > $maxSMTPipConnects ) {
                    $this->{prepend} = "[IPfrequency]";
                     $this->{messagereason} = "'$ConIp550' passed limit($maxSMTPipConnects) of ip  connection frequency";

                    mlog( $fh, "$tlit $this->{messagereason}")
                      if $SessionLog >= 2
                          && $IPNumTries{$ConIp550} > $maxSMTPipConnects + 1;
                    mlog( $fh,"$tlit $this->{messagereason}")
                      if $SessionLog
                          && $IPNumTries{$ConIp550} == $maxSMTPipConnects + 1;
                    pbAdd( $fh, $this->{ip}, 'ifValencePB', "IPfrequency" ) if $DoFrequencyIP!=2;
                    if ( $DoFrequencyIP == 1 ) {
                        $Stats{smtpConnLimitFreq}++;
                        seterror( $fh, "554 5.7.1 too frequent connections for '$ConIp550'", 1 );
                        return;
                    }
                }
            }


            if ($ForceFakedLocalHelo && !($fhTestMode || $allTestMode)) {
                if (! ForgedHeloOK($fh) ) {
                    $reply =
                      $SenderInvalidError
                      ? "$SenderInvalidError"
                      : "$SpamError";
                    $reply =~ s/REASON/Forged HELO/go;
                    seterror( $fh, $reply, 1 );
                    return;
                  }
            }

            &IPinHeloOK($fh);

            if ($ForceValidateHelo && !($ihTestMode || $allTestMode)) {
                if (! invalidHeloOK($fh,\$this->{helo})) {
                    $Stats{invalidHelo}++ ;
                    $this->{prepend}="[InvalidHELO]";
                    mlog($fh,"[spam found] ($this->{messagereason})") ;
                    $reply=$SenderInvalidError ? "$SenderInvalidError" : "$SpamError" ;
                    $reply =~ s/REASON/Helo invalid/go;
                    seterror($fh,$reply,1);
                    return;
                }
                if (! validHeloOK($fh,\$this->{helo})) {
                    $Stats{invalidHelo}++ ;
                    $this->{prepend}="[InvalidHELO]";
                    mlog($fh,"[spam found] ($this->{messagereason})");
                    $reply=$SenderInvalidError ? "$SenderInvalidError" : "$SpamError" ;
                    $reply =~ s/REASON/Helo invalid/go;
                    seterror($fh,$reply,1);
                    return;
                }
            }

            if ($ForceNoValidLocalSender && !($allTestMode || $DoNoValidLocalSender==4)) {
                if (! LocalSenderOK( $fh, $this->{ip} ) ) {
                    $reply =
                      $SenderInvalidError
                      ? "$SenderInvalidError"
                      : "$SpamError";
                    $reply =~ s/REASON/Unknown Sender in Local Domain/go;
                    $Stats{senderInvalidLocals}++;
                    $this->{prepend} = "[InvalidLocalSender]";
                    mlog( $fh, "[spam found] Unknown Sender in Local Domain" );
                    seterror( $fh, $reply, 1 );
                    return;
                }
                if (! NoSpoofingOK( $fh, 'mailfrom' ) ) {
                    $reply =
                      $SenderInvalidError
                      ? "$SenderInvalidError"
                      : "$SpamError";
                    $reply =~ s/REASON/Spoofing Sender in Local Domain/go;
                    $Stats{senderInvalidLocals}++;
                    $this->{prepend} = "[InvalidLocalSender]";
                    mlog( $fh, "[spam found] Spoofing Sender in Local Domain" );
                    seterror( $fh, $reply, 1 );
                    return;
                }
            }

            if ($ForceRBLCache && !($rblTestMode || $allTestMode)) {
                if (! RBLCacheOK($fh,$this->{ip},0))  {
                    return;
                }
            }
        }

############################################ end !relayok ###################

        if ($EnableSRS &&
            $CanUseSRS  &&
            $this->{relayok} &&
            ! localmail($this->{mailfrom}) &&
            ! $this->{isbounce} &&
            ! ( $this->{mailfrom} && matchSL($this->{mailfrom},'SRSno'))) {

            # rewrite sender addresses when relaying through Relay Host
            my $tmpfrom;
            $this->{prepend}='';
            my $srs = Mail::SRS->new(
                Secret=>$SRSSecretKey,
                MaxAge=>$SRSTimestampMaxAge,
                HashLength=>$SRSHashLength,
                AlwaysRewrite=>1
              );
            if (!eval{$tmpfrom=$srs->reverse($this->{mailfrom})} &&
                eval{$tmpfrom=$srs->forward($this->{mailfrom},$SRSAliasDomain)}) {
                mlog($fh, "SRS rewriting sender '$this->{mailfrom}' into '$tmpfrom'",1);
                $l =~ s/\Q$this->{mailfrom}\E/$tmpfrom/;
            } else {
                mlog($fh, "SRS rewriting sender '$this->{mailfrom}' failed!",1);
            }
        }


        if (   ! $this->{relayok}
            && ! ($this->{noprocessing} & 1)
            && ! $this->{whitelisted}
            && ! $this->{pbwhite}
            && ! $this->{nopb}
            && ! $this->{rwlok}
            && ! $this->{acceptall}
            && ! $this->{contentonly}
            && ! $this->{noblockingips}
            && $DoRFC822 & 2
            && ! localmail($this->{mailfrom})
            && $this->{mailfrom} =~ /(($EmailAdrRe)\@($EmailDomainRe))/o)
        {
            my ($adr,$user,$dom) = ($1,$2,$3);
            my $error;
            my $nonASCII;
            my $ns='ANY';  # less strict than 'NS', ANY registration should be fine
            if (($nonASCII = ! is_7bit_clean(\$adr)) || $adr !~ /$RFC822RE/o ) {
                $error = 'RFC822';
            }
            if ($dom !~ /^$IPRe$/o) {
                if ($dom !~ /([^\.]+(?:$URIBLCCTLDSRE|\.$TLDSRE))$/i) {
                    $error .= ', ' if $error;
                    $error = 'Invalid-Sender-Domain';
                    $this->{invalidSenderDomain} = lc $dom;
                }
                if (exists($RFC822dom{lc $dom}) || (${defined *{'yield'}} && defined($ns = getRRData(${defined *{'yield'}}, (defined *{'yield'}?$ns:''))) && $ns eq '0' && ($lastDNSerror eq 'NXDOMAIN' || $lastDNSerror eq 'NOERROR'))) {
                    $error .= ', ' if $error;
                    $error = "Missing-NameServer-Registration: $1";
                    $RFC822dom{lc $dom} = time unless exists($RFC822dom{lc $dom});
                    $this->{invalidSenderDomain} = lc $dom;
                }
            }
            if ($error) {
                $this->{prepend}='[MalformedAddress]';
                mlog($fh,"malformed address: '$adr' - $error");
                $Stats{senderInvalidLocals}++;
                pbAdd( $fh, $this->{ip}, 'nofromValencePB', 'From-missing' );
                $adr = encodeMimeWord($adr,'B','UTF-8') if $nonASCII; # be nice to the hackers server
                if($MaxErrors && ++$this->{serverErrors} > $MaxErrors) {
                    MaxErrorsFailed($fh,
                    "553 Malformed ($error) address: $adr\r\n421 <$myName> closing transmission\r\n",
                    "max errors (MaxErrors=$MaxErrors) exceeded -- dropping connection after '$error' sender validation");
                    return;
                }
                sendque($fh, "553 Malformed ($error) address: $adr\r\n");
                return;
            }
        } elsif (   ! $this->{relayok}   # we should check the domain anyway for valid DNS registration
            && ! localmail($this->{mailfrom})
            && $this->{mailfrom} =~ /(($EmailAdrRe)\@($EmailDomainRe))/o)
        {
            my ($adr,$user,$dom) = ($1,$2,$3);
            my $ns='NS';
            if ($dom !~ /^$IPRe$/o) {
                if ($dom !~ /([^\.]+(?:$URIBLCCTLDSRE|\.$TLDSRE))$/i) {
                    $this->{invalidSenderDomain} = lc $dom;
                    mlog(0,"warning: the sender address contains an invalid top level domain name '$dom' - all DNS queries will be skipped!") if $ConnectionLog;
                }
                if (exists($RFC822dom{lc $dom}) || (${defined *{'yield'}} && defined($ns = getRRData(${defined *{'yield'}}, (defined *{'yield'}?$ns:''))) && $ns eq '0' && ($lastDNSerror eq 'NXDOMAIN' || $lastDNSerror eq 'NOERROR'))) {
                    $RFC822dom{lc $dom} = time;
                    $this->{invalidSenderDomain} = lc $dom;
                    mlog(0,"warning: can't find a name server registration for the sender domain '$dom' - all DNS queries will be skipped!") if $ConnectionLog;
                }
            }
        }
    } elsif($l=~/^ *(VRFY|EXPN) *([^\r\n]*)/io) {
        $this->{lastcmd} = $1;
        my $e=$2;
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;

        if ( $DisableVRFY && !$this->{relayok} )
        {
            $this->{prepend}="[unsupported_$this->{lastcmd}]";
            mlog($fh,"$this->{lastcmd} not allowed");
            if($MaxErrors && ++$this->{serverErrors} > $MaxErrors) {
                MaxErrorsFailed($fh,
                "502 $this->{lastcmd} not supported\r\n421 <$myName> closing transmission\r\n",
                "max errors (MaxErrors=$MaxErrors) exceeded -- dropping connection after $this->{lastcmd}");
                return;
            }
            sendque($fh, "502 $this->{lastcmd} not supported\r\n");
            return;
        }

        my ($u,$h);
        my ($str, $gen, $day, $hash, $orig_user) = ($e =~ /(prvs=(\d)(\d\d\d)(\w{6})=([^\r\n]*))/o);
        $l =~ s/$str/$orig_user/ if ($orig_user);  # remove our BATV-Tag from VRFY address

        # recipient replacment should be done next to here !
        if ($ReplaceRecpt) {
            if ($l=~/ *(?:VRFY|EXPN)\s*<*([^\r\n>]*)/io) {
                my $midpart  = $1;
                my $orgmidpart = $midpart;
                if ($midpart) {
                  if($EnableBangPath && $midpart=~/([a-z\-_\.]+)!([a-z\-_\.]+)$/io) {
                      $midpart = "$2\@$1";
                  }
                  my $mf = batv_remove_tag(0,lc $this->{mailfrom},'');
                  my $newmidpart = RcptReplace($midpart,$mf,'RecRepRegex');
                  if (lc $newmidpart ne lc $midpart) {
                      $l =~ s/$orgmidpart/$newmidpart/i;
                      mlog($fh,"info: $this->{lastcmd} recipient $orgmidpart replaced with $newmidpart");
                  }
                }
            }
        }
    } elsif($l=~/rcpt to: *([^\r\n]*)/io) {
        $this->{lastcmd} = 'RCPT TO';
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
        delete $this->{orgrcpt};
        my $e=$1;

        # if MAIL FROM: .... AUTH=... was supplied , we check here if the AUTH was successful (got reply 235)
        if($EnforceAuth && &matchFH($fh,@lsn2I) && ! $this->{authenticated} && ! $this->{DisableAUTH}) {
            NoLoopSyswrite($fh,"530 5.7.0 Authentication required\r\n",0);
            mlog($fh,"'RCPT TO:' submited without previouse AUTH - 'EnforceAuth' is set to 'ON' for 'listenPort2'",1);
            done($fh);
            return;
        }

        my ($u,$h);

        my $foreignSRS;         # first check and remove any local SRS signing
        if (! $this->{relayok} && $EnableSRS && $CanUseSRS) {

            # validate incoming bounces
            my $tmpto;
            my $failed;
            my $srs;
            $srs = Mail::SRS->new(
                Secret=>$SRSSecretKey,
                MaxAge=>$SRSTimestampMaxAge,
                HashLength=>$SRSHashLength,
                AlwaysRewrite=>1
              ) if ($e=~/^<?(SRS[01][=+-][^\r\n>]*)/io);
            if ($e=~/^<?(SRS0[=+-][^\r\n>]*)/io) {
                my $asrs0 = $1;
                if (eval{$tmpto=$srs->reverse($asrs0)}) {
                    mlog($fh,"info: SRS - replace $asrs0 with $tmpto") if $SessionLog > 1;
                    $this->{SRSorgAddress} = $asrs0 = quotemeta($asrs0);
                    $this->{SRSnewAddress} = $tmpto;
                    $l=~s/$asrs0/$tmpto/;
                    $e=$tmpto;
                    $this->{backsctrdone} = $this->{msgidsigdone} = $this->{nodelay} = $this->{isbounce} = 1;
                    $this->{prepend} = '[isbounce]';
                    mlog($fh,"bounce message detected");
                    $this->{prepend} = '';
                    if ($e =~ /$EmailAdrRe\@($EmailDomainRe)/io && ! localmail($1)) {
                        $foreignSRS = 1;   # our SRS was done for a foreign domain
                        mlog($fh,"info: SRS - foreign recipient domain '$1' detected") if $SessionLog > 1;
                    }
                } else {
                    $failed = $@ || 'user not local';
                }
            } elsif ($e=~/^<?(SRS1[=+-][^\r\n>]*)/io) {
                my $asrs1 = $1;
                my $asrs0;
                if (eval{$asrs0=$srs->reverse($asrs1)}) {
                    mlog($fh,"info: SRS - replace $asrs1 with $asrs0") if $SessionLog > 1;
                    my $srs0_dom;
                    $srs0_dom = $1 if $asrs0 =~ /\@($EmailDomainRe)$/io;
                    if (eval{$tmpto=$srs->reverse($asrs0)}) {
                        mlog($fh,"info: SRS - replace $asrs0 with $tmpto") if $SessionLog > 1;
                        $this->{SRSorgAddress} = $asrs1 = quotemeta($asrs1);
                        $this->{SRSnewAddress} = $tmpto;
                        $l=~s/$asrs1/$tmpto/;
                        $e=$tmpto;
                        $this->{backsctrdone} = $this->{msgidsigdone} = $this->{nodelay} = $this->{isbounce} = 1;
                        $this->{prepend} = '[isbounce]';
                        mlog($fh,"bounce message detected");
                        $this->{prepend} = '';
                        if ($e =~ /$EmailAdrRe\@($EmailDomainRe)/io && ! localmail($1)) {
                            $foreignSRS = 1;  # our SRS was done for a foreign domain
                            mlog($fh,"info: SRS - foreign recipient domain '$1' detected") if $SessionLog > 1;
                        }
                    } else {  # SRS1 was OK for us - possibly the SRS0 comes from another host if the domain in SRS0 is not local
                        my $err = $@;
                        if ( localmail($srs0_dom) ) {
                            $failed = $err || 'user not local';
                        } else {
                            $this->{SRSorgAddress} = $asrs1 = quotemeta($asrs1);
                            $this->{SRSnewAddress} = $asrs0;
                            $l=~s/$asrs1/$asrs0/;
                            $e=$asrs0;
                            $this->{backsctrdone} = $this->{msgidsigdone} = $this->{nodelay} = $this->{isbounce} = 1;
                            $this->{prepend} = '[isbounce]';
                            mlog($fh,"bounce message detected");
                            $this->{prepend} = '';
                            if ($e =~ /$EmailAdrRe\@($EmailDomainRe)/io && ! localmail($1)) {
                                $foreignSRS = 1;  # our SRS was done for a foreign domain
                                mlog($fh,"info: SRS - foreign recipient domain '$1' detected") if $SessionLog > 1;
                            }
                        }
                    }
                } else {
                    $failed = $@ || 'user not local';
                }
            } else {
                $this->{invalidSRSBounce} = 1 if $this->{isbounce};
            }
            if ($failed && !($this->{ispip}) && !(matchIP($this->{ip},'noSRS',0,1))) {
                $failed =~ s/\r|\n//go;
                $this->{prepend}='[RelayAttempt]';
                $this->{messagereason} = "invalid SRS signature: $failed";
                mlog( $fh, $this->{messagereason} );
                $Stats{rcptRelayRejected}++;
                pbAdd($fh,$this->{ip},'rlValencePB','RelayAttempt',0);
                if($MaxErrors && ++$this->{serverErrors} > $MaxErrors) {
                    MaxErrorsFailed($fh,
                    "551 5.7.6 $this->{messagereason}\r\n421 <$myName> closing transmission\r\n" ,
                    "max errors (MaxErrors=$MaxErrors) exceeded -- dropping connection - after $this->{messagereason}");
                    return;
                }
                sendque($fh,"551 5.7.6 $this->{messagereason}\r\n");
                return;
            }
        }

        $e = batv_remove_tag(0,$e,'');

        # BATV check and stuff for rcpt to
        if ($this->{relayok}) {                   # it's outgoing mail
            $l=~/rcpt to:\s*<*([^\r\n>]*)/io;    # get the recipient address
            my $rt = $1;
            if ($remindBATVTag && $this->{isbounce} && exists $BATVTag{lc($rt)}) {        # if we remind strange Tags - does the Tag exists
                if ( my ($gen, $day, $hash, $orig_user) = ($BATVTag{lc($rt)} =~ /^prvs=(\d)(\d\d\d)(\w{6})=([^\r\n]*)/o) ) {  # get the Tag details
                    ($orig_user) = ($BATVTag{lc($rt)} =~ /^prvs=[\da-zA-Z]+=([^\r\n]*)/o) unless $orig_user;  # get the Tag details from invalid BATV signature
                    my $today = (time / 86400) % 1000;                   # how old is the Tag
                    my $dt = ($day - $today + 1000) % 1000;
                    if ($dt <= 7) {
                        $l =~ s/$rt/$BATVTag{lc($rt)}/i;          # the age is OK - less than 8 days - so replace recipient address with tagged address
                        mlog($fh,"reminded BATV-Tag $BATVTag{lc($rt)} for recipient $rt") if ($BATVLog >= 2);
                    } else {
                        delete $BATVTag{lc($rt)};
                    }
                } else {
                    $l =~ s/$rt/$BATVTag{lc($rt)}/i;          #  replace recipient address with the foreign private BATV tagged address
                    mlog($fh,"reminded BATV-Tag $BATVTag{lc($rt)} for recipient $rt") if ($BATVLog >= 2);
                }
            }
        } else {                                # it' incoming mail
            $l=~/rcpt to:\s*<*([^\r\n>]*)/io;  # get the recipient address
            my $rt = $1;
            my $ok;
            my $res;
            my $lrt = batv_remove_tag($fh,$rt,'BATVrcpt');  # remove any Tag - store it ->{BATVrcpt}
            my $tlit = &tlit($DoBATV);
            if ($DoBATV) {      # we have to do BATV-check
               $l =~ s/\Q$rt\E/$lrt/i if ($removeBATVTag && lc($rt) ne lc($lrt));    # replace tagged address with simple address
               ($res,$ok) = &batv_rcpt_in($fh,$rt);      # check if BATV is OK
               if ($ok == 1) {      # if OK remove $BATVTag{}
                    $l =~ s/\Q$rt\E/$lrt/i if ($removeBATVTag && lc($rt) ne lc($lrt));    # replace tagged address with simple address
                    mlog($fh,"BATV-Tag removed from recipient address $rt") if ($BATVLog && lc($lrt) ne lc($rt) && $removeBATVTag);
                    mlog($fh,"$tlit BATV-check pass for bounce sender \<$this->{mailfrom}\> rcpt $rt") if ($BATVLog && $res ne $rt);
                    $this->{msgidsigdone} = 1 if ($res ne $rt && $DoBATV != 4);       # do no other Backscatter tests
                    $this->{backsctrdone} = 1 if ($res ne $rt && $DoBATV != 4);
               } elsif ($ok == 0) {             # BATV check failed -> SPAM
                    $l =~ s/\Q$rt\E/$lrt/i if ($removeBATVTag && lc($rt) ne lc($lrt));    # replace tagged address with simple address
                    mlog($fh,"BATV-Tag removed from recipient address $rt") if ($BATVLog && lc($lrt) ne lc($rt) && $removeBATVTag);
                    $this->{msgidsigdone} = '';
                    $this->{backsctrdone} = '';

                    $this->{messagereason}="BATV check failed for bounce sender \<$this->{mailfrom}\> rcpt $rt";
                    $this->{prepend}='[BATV]';
                    mlog($fh,"$tlit $this->{messagereason}") if ($BATVLog && $DoBATV != 4);
                    if ($DoBATV != 2 && $DoBATV != 4) {  # if block or score
                        pbWhiteDelete($fh,$this->{ip});
                        pbAdd($fh,$this->{ip},'batvValencePB',"BATV-check-failed");
                        $Stats{batvErrors}++;
                        my $done = $DoBATV == 1 ? 1 : 0;     # if we block on BATV failed - tell the client
                        if ($Back250OKISP && $this->{ispip}) {
                            $this->{accBackISPIP} = 1;
                            mlog($fh,"info: force sending 250 OK to ISP for failed bounced message") if $BacksctrLog;
                        } else {
                            thisIsSpam($fh,$this->{messagereason},$BackLog,'554 5.7.10 BATV error - bounce address - message was never sent by this domain - RCPT $rt',0,0,1) if $done;
                            return if $done;
                        }
                    }
               } else {               # BATV-check not needed, not possible or exception
                    $l =~ s/\Q$rt\E/$lrt/i if ($removeBATVTag && lc($rt) ne lc($lrt));    # replace tagged address with simple address
                    $this->{msgidsigdone} = '';
                    $this->{backsctrdone} = '';
                    mlog($fh,"BATV-Tag removed from recipient address $rt") if ($BATVLog && lc($lrt) ne lc($rt) && $removeBATVTag);
               }
            } else {            # no BATV-check defined
                $l =~ s/\Q$rt\E/$lrt/i if ($removeBATVTag && lc($rt) ne lc($lrt));    # replace tagged address with simple address
                mlog($fh,"BATV-Tag removed from recipient address $rt") if ($BATVLog >= 2 && lc($lrt) ne lc($rt) && $removeBATVTag);
            }
        }

        # end BATV for rcpt to
        $this->{prepend}='';

        # recipient replacment should be done next to here !
        delete $this->{orgrcpt};
        if ($ReplaceRecpt) {
            if ($l=~/rcpt to:\s*<*([^\r\n>]*)/io) {
                my $midpart  = $1;
                $midpart = batv_remove_tag(0,$midpart,'');
                my $orgmidpart = $midpart;
                if ($midpart) {
                  my $bpa = 0;
                  if($EnableBangPath && $midpart=~/([a-z\-_\.]+)!([a-z\-_\.]+)$/io) {
                      $midpart = "$2\@$1";
                  }
                  my $mf = $this->{mailfrom};
                  $mf = batv_remove_tag(0,$mf,'');
                  my $newmidpart = RcptReplace($midpart,$mf,'RecRepRegex');
                  if (lc $newmidpart ne lc $midpart) {
                      $l =~ s/\Q$orgmidpart\E/$newmidpart/i;
                      mlog($fh,"info: recipient $orgmidpart replaced with $newmidpart");
                      $this->{myheader}.="X-Assp-Recipient: recipient $orgmidpart replaced with $newmidpart\r\n";
                      $this->{orgrcpt} = $orgmidpart;
                  }
                }
            }
            $l=~/rcpt to: *([^\r\n]*)/io;
            $e = batv_remove_tag(0,$1,'');
        }

        #enforce valid email address pattern - RFC822
        if ($DoRFC822 & 1) {
            if ($e=~/<*([^\r\n>]*)/io) {
                my $RO_e = $1;
                my $nonASCII;
                my $error;
                if ($RO_e !~ /RSBM_.*?x2DXx2DX\d+\Q$maillogExt\E\@/i) {
                    if (($nonASCII = ! is_7bit_clean(\$RO_e)) || $RO_e !~ /$RFC822RE/o ) {
                        $error = 'RFC822';
                    }
                    if ($error) {
                        $this->{prepend}='[MalformedAddress]';
                        mlog($fh,"malformed address: '$RO_e' - $error");
                        $Stats{rcptRelayRejected}++;
                        $RO_e = encodeMimeWord($RO_e,'B','UTF-8') if $nonASCII; # be nice to the hackers server
                        pbAdd( $fh, $this->{ip}, 'irValencePB', 'InvalidAddress' );
                        if($MaxErrors && ++$this->{serverErrors} > $MaxErrors) {
                            MaxErrorsFailed($fh,
                            "553 Malformed ($error) address: $RO_e\r\n421 <$myName> closing transmission\r\n",
                            "max errors (MaxErrors=$MaxErrors) exceeded -- dropping connection after '$error' recipient validation");
                            return;
                        }
                        sendque($fh, "553 Malformed ($error) address: $RO_e\r\n");
                        return;
                    }
                }
            }
        }

        if ( ! $this->{relayok} && $e !~ /ORCPT/o && $e =~ /[\!\@]\S*\@/o  ) {
            # blatent attempt at relaying
            $this->{prepend}='[RelayAttempt]';
            $this->{messagereason} = "relay attempt blocked for (evil): $e";
            mlog( $fh, $this->{messagereason} );
            pbAdd( $fh, $this->{ip}, 'rlValencePB', 'RelayAttempt', 0 );
            $Stats{rcptRelayRejected}++;
            if($MaxErrors && ++$this->{serverErrors} > $MaxErrors) {
                MaxErrorsFailed($fh,
                $NoRelaying."\r\n421 <$myName> closing transmission\r\n" ,
                "max errors (MaxErrors=$MaxErrors) exceeded -- dropping connection - after ORCPT");
                return;
            }
            sendque($fh, $NoRelaying."\r\n");
            return;
        } elsif($EnableBangPath && $e=~/([a-z\-_\.]+)!([a-z\-_\.]+)$/io) {

   # someone give me one good reason why I should support bang paths! grumble...
            $u="$2\@";
            $h=$1;
        } elsif($l=~/rcpt to:[^\r\n]*?($EmailAdrRe\@)($EmailDomainRe)/io) {
            my $buh = batv_remove_tag(0,"$1$2",'');
            $buh =~ /($EmailAdrRe\@)($EmailDomainRe)/io;
            ($u,$h)=($1,$2);
        } elsif($l=~/rcpt to:[^\r\n]*?(\"$EmailAdrRe\"\@)($EmailDomainRe)/io) {
            ($u,$h)=($1,$2);
            my $buh = batv_remove_tag(0,"$u$h",'');
            $buh =~ /($EmailAdrRe\@)($EmailDomainRe)/io;
            ($u,$h)=($1,$2);
            $u =~ s/\"//go;
        } elsif($defaultLocalHost && $l=~/rcpt to:[^\r\n]*?<($EmailAdrRe)>/io) {
            ($u,$h)=($1,$defaultLocalHost);
            $u.='@';
        } else {

            # couldn't understand recipient
            $this->{prepend}="[RelayAttempt]";
            mlog($fh,"relay attempt blocked for (parsing): $e");

            $Stats{rcptRelayRejected}++;
            if($MaxErrors && ++$this->{serverErrors} > $MaxErrors) {
                MaxErrorsFailed($fh,
                $NoRelaying."\r\n421 <$myName> closing transmission\r\n" ,
                "max errors (MaxErrors=$MaxErrors) exceeded -- dropping connection - after relay (parsing)");
                return;
            }
            sendque($fh, $NoRelaying."\r\n");
            return;
        }
        my $rcptislocal=localmail($h);
        $this->{nodelay} ||= 1 if ! $this->{relayok} && matchSL("$u$h",'noDelayAddresses');

        if ($rcptislocal) {
            $this->{mailfrom} = &batv_remove_tag(0,$this->{mailfrom},'') if localmail($this->{mailfrom});
            if ( ! $this->{relayok} && PersBlackFind("$u$h",$this->{mailfrom}) ) {
                my $addr = (exists $this->{orgrcpt}) ? $this->{orgrcpt} : "$u$h";
                my $reply = "550 mailbox for <$addr> is unavailable\r\n";
                $reply = "250 OK\r\n" if $send250OK or ($this->{ispip} && $send250OKISP);
                sendque( $fh, $reply );
                $this->{prepend} = "[PersonalBlack]";
                $this->{orgrcpt} = "$u$h";
                mlog( $fh, "[spam found] ($this->{mailfrom} rejected by personal black address list of $u$h - skipped recipient)" ,0,3);
                delete $this->{orgrcpt};
                return;
            } elsif (lc $u eq "abuse\@" && $sendAllAbuse) {
                # accept abuse catchall addresses
                if ($sendAllAbuse=~/$EmailAdrRe\@($EmailDomainRe)/io) {
                    $h=$1;
                    $l="RCPT TO:\<$sendAllAbuse\>\r\n";
                    $this->{noprocessing} = 1 if $sendAllAbuseNP;
                }
            } elsif (lc $u eq "postmaster\@" && $sendAllPostmaster) {
                # accept postmaster catchall addresses
                if ($sendAllPostmaster=~/$EmailAdrRe\@($EmailDomainRe)/io) {
                    $h=$1;
                    $l="RCPT TO:\<$sendAllPostmaster\>\r\n";
                    $this->{noprocessing} = 1 if $sendAllPostmasterNP;
                }
            } elsif ( matchSL( "$u$h", 'RejectTheseLocalAddresses' ) ) {
                if ($NoValidRecipient) {
                    $reply = $NoValidRecipient."\r\n";
                    $reply =~ s/EMAILADDRESS/$u$h/go;
                } else {
                    $reply = "550 5.1.1 User unknown $u$h\r\n";
                }
                sendque( $fh, $reply );
                $this->{prepend} = '[BounceAddress]';
                mlog( $fh, "rejected by bounce address list: $u$h" )
                  if $ValidateUserLog;
                return;
            } elsif (   (!$this->{nocollect} && matchSL( "$u$h", 'spamaddresses' ) )
                	 or ($UseTrapToCollect && &pbTrapFind($fh,"$u$h") )
                     or ($UseTrapToCollect && matchSL("$u$h",'spamtrapaddresses' && ! matchSL("$u$h",'noPenaltyMakeTraps')) )
                    )
            {
                $this->{addressedToSpamBucket}="$u$h";
                my $collectaddress; $collectaddress = $sendAllSpam if $sendAllSpam;
                $collectaddress=$sendAllCollect if $sendAllCollect;
                if ($collectaddress=~/($EmailAdrRe\@)($EmailDomainRe)/io) {
                    $u=$1;
                    $h=$2;
                    $l="RCPT TO: \<$collectaddress\>\r\n";
                }
            }
            if (!$this->{relayok} && !$this->{acceptall} && (&pbTrapFind($fh,"$u$h") || ( matchSL("$u$h",'spamtrapaddresses') && ! matchSL("$u$h",'noPenaltyMakeTraps')))) {

                $this->{addressedToPenaltyTrap}=1;
                $this->{prepend}="[Trap]";
                pbWhiteDelete($fh,$this->{ip});
                $this->{whitelisted} = '';
                my $mf = batv_remove_tag(0,lc $this->{mailfrom},'');
                if ( &Whitelist($mf,"$u$h") ) {
            		&Whitelist($mf,"$u$h",'delete');
            		mlog( $fh, "penalty trap: whitelist deletion: $this->{mailfrom}" );
                }
                RWLCacheAdd( $this->{ip}, 4 );  # fake RWL none
                mlog($fh,"penalty trap address: $u$h") if $PenaltyLog;
                $this->{messagereason} = "penalty trap address: $u$h";
                pbAdd($fh,$this->{ip},'stValencePB','penaltytrap',0) ;
                $Stats{penaltytrap}++;
                delayWhiteExpire($fh);
                $reply = "550 5.1.1 User unknown: $u$h\r\n";
                if ($PenaltyTrapPolite) {
                    $reply = $PenaltyTrapPolite;
                    $reply =~ s/EMAILADDRESS/$u$h/go;
                }
                seterror( $fh, "$reply", 1 );
                return;
            }
        }
        if ($noProcessing) {
            $this->{uhnoprocessing}=0;
            $this->{rcptnoprocessing}=0;

            if(matchSL("$u$h",'noProcessing')) {
                mlogRe($fh,"$u$h",'noProcessing','noprocessing');
                $this->{uhnoprocessing}=1 if $LocalAddressesNP;
                $this->{delaydone}=1;
                $this->{rcptnoprocessing}=1;
            }
        }

        my $localEI = $EmailInterfaceDomains ? matchSL("\@$h",'EmailInterfaceDomains') : localmail($h);
        my $isEmailInterface =
                 (     $localEI
                    && (   lc $u eq lc "$EmailSpam\@"
                        || lc $u eq lc "$EmailHam\@"
                        || lc $u eq lc "$EmailWhitelistAdd\@"
                        || lc $u eq lc "$EmailWhitelistRemove\@"
                        || lc $u eq lc "$EmailRedlistAdd\@"
                        || lc $u eq lc "$EmailHelp\@"
                        || lc $u eq lc "$EmailAnalyze\@"
                        || lc $u eq lc "$EmailRedlistRemove\@"
                        || lc $u eq lc "$EmailSpamLoverAdd\@"
                        || lc $u eq lc "$EmailSpamLoverRemove\@"
                        || lc $u eq lc "$EmailNoProcessingAdd\@"
                        || lc $u eq lc "$EmailNoProcessingRemove\@"
                        || lc $u eq lc "$EmailBlackAdd\@"
                        || lc $u eq lc "$EmailBlackRemove\@"
                        || lc $u eq lc "$EmailPersBlackAdd\@"
                        || lc $u eq lc "$EmailPersBlackRemove\@"
                        || lc $u =~ /^RSBM_.+?\Q$maillogExt\E\@$/i
                        || lc $u eq lc "$EmailBlockReport\@"
                       )
                 );
        my $emailok;
        $emailok = 1
          if (   $EmailInterfaceOk
              && $this->{senderok} ne '2'
              && $this->{senderok} ne '3'
              && ( $this->{relayok} || $this->{senderok} eq '1'  )
              && $isEmailInterface
             );

        # skip check when RELAYOK or EMAIL-Interface
        my $uh = "$u$h";
        $this->{alllog} = 1 if $allLogRe && $uh =~ /$allLogReRE/;

        if ( !$this->{uhnoprocessing} && !$emailok && !$this->{relayok} ) {

            my $trapfound = 0;

            if (   $LocalAddresses_Flat
                || $DoLDAP
                || ($DoVRFY &&
                    (scalar( keys %DomainVRFYMTA ) || scalar( keys %FlatVRFYMTA ))
                   )
               )
            {
                $this->{islocalmailaddress} = 0;
            }

            if ($SepChar) {
                if ( $u =~ /(.+?)\Q$SepChar\E/ ) {
                    $uh = "$1\@$h";
                    $uh =~ s/"//o;
                }
            }

            if ( &LDAPCacheFind( $uh, $DoLDAP ? "LDAP" : "VRFY") ) {
                $this->{islocalmailaddress} = 1;
                d("$uh validated by ldapcache\n");
                mlog( $fh, "$uh validated by ldapcache" )
                  if $ValidateUserLog == 3;
            }
            elsif ( matchSL( "$uh", 'spamaddresses' ) ) {
                $this->{islocalmailaddress} = 1;
                d("$uh validated by spamaddresses list\n");
                mlog( $fh, "$uh validated by spamaddresses list" )
                  if $ValidateUserLog == 3;
            }
            elsif ( !$this->{islocalmailaddress}
                && $uh =~ /^([^@]*)(@.*)$/o
                && matchSL( $2, 'LocalAddresses_Flat' ) )
            {
                $this->{islocalmailaddress} = 1;
                d("$2 validated by LocalAddresses_Flat\n");
                mlog( $fh, "$2 validated by LocalAddresses_Flat" )
                  if $ValidateUserLog == 3;
            }
            elsif ( !$this->{islocalmailaddress}
                && $LocalAddresses_Flat_Domains
                && $uh =~ /^([^@]*@)(.*)$/o
                && matchSL( $2, 'LocalAddresses_Flat' ) )
            {
                $this->{islocalmailaddress} = 1;
                d("$2 validated by LocalAddresses_Flat\n");
                mlog( $fh, "$2 validated by LocalAddresses_Flat" )
                  if $ValidateUserLog == 3;

            }
            elsif ( !$this->{islocalmailaddress} && matchSL( $uh, 'LocalAddresses_Flat' ) )
            {
                $this->{islocalmailaddress} = 1;
                d("$uh validated by LocalAddresses_Flat\n");
                mlog( $fh, "$uh validated by LocalAddresses_Flat" )
                  if $ValidateUserLog == 3;

                # Need another check?
            }
            elsif ( !$this->{islocalmailaddress} ) {

                # check recipient against LDAP ?
                $this->{islocalmailaddress} = &localmailaddress( $fh, $uh )
                  if (
                    ( $DoLDAP && $CanUseLDAP )
                    or ( $DoVRFY && $CanUseNetSMTP
                        && $uh =~ /^([^@]*@)(.*)$/o
                        && (&matchHashKey('DomainVRFYMTA', lc $2 )
                            or &matchHashKey('FlatVRFYMTA', lc "\@$2" ) )
                    )
                  );
            }
            if (! $this->{islocalmailaddress} && $UseTrapToCollect && pbTrapFind( $fh, $uh ) ||
                    ( matchSL($uh,'spamtrapaddresses') && ! matchSL($uh,'noPenaltyMakeTraps')))
            {
                $this->{islocalmailaddress} = 1;
                $trapfound = 1;
                d("$uh validated by generated trapaddresses list\n");
                mlog( $fh, "$uh validated by generated trapaddresses list" )
                  if $ValidateUserLog == 3;
            }
            pbTrapDelete($uh) if $this->{islocalmailaddress} && ! $trapfound;
        } else {
            $this->{islocalmailaddress} = localmail($h);
        }

        if(!$foreignSRS && !$this->{relayok} && !$nolocalDomains && (!$rcptislocal || $uh=~/\%/o) || $u =~/\@\w+/o) {
            $this->{prepend}="[RelayAttempt]";
            mlog($fh,"relay attempt blocked for: $uh");
            $this->{messagereason}="relay attempt blocked for: $uh";
            pbAdd($fh,$this->{ip},'rlValencePB','RelayAttempt');
            $Stats{rcptRelayRejected}++;
            delayWhiteExpire($fh);
            if($MaxErrors && ++$this->{serverErrors} > $MaxErrors) {
                MaxErrorsFailed($fh,
                $NoRelaying."\r\n421 <$myName> closing transmission\r\n",
                "max errors (MaxErrors=$MaxErrors) exceeded -- dropping connection - after relay attemp");
                return;
            }
            sendque($fh, $NoRelaying."\r\n");
            return;
        }

        $this->{nobayesian} ||= matchSL($uh,'noBayesian');
        $this->{nocollect} ||= matchSL($uh,'noCollecting');
        $this->{noscan} ||= matchSL( $uh,'noScan');

       # check if this email is to be processed at all if in ProcessOnlyTestMode
        if( $poTestMode && ! ($this->{noprocessing} & 1) && $this->{islocalmailaddress}) {

            if( matchSL($this->{mailfrom},'processOnlyAddresses'))
            {
                $this->{passingreason} = "envelope sender $this->{mailfrom} is on processOnlyAddresses";
            } elsif( matchSL($uh,'processOnlyAddresses'))
            {
                $this->{passingreason} = "envelope recipient $uh is on processOnlyAddresses";
            } else
            {
                $this->{noprocessing} = ($this->{noprocessing} | 1);
                $this->{passingreason} = "message proxied without processing - poTestMode('Enable Process Only Addresses') is enabled";
            }
        }
        if (matchSL($uh,'spamaddresses')) {

            $this->{addressedToSpamBucket}=$uh;
        }

        if (   (matchSL($uh,'InternalAddresses')  &&  ! localmail($this->{mailfrom}))
            || (matchSL($uh,'InternalAndWhiteAddresses') && ! ( localmail($this->{mailfrom}) || Whitelist($this->{mailfrom},$uh, undef)) )
           )
        {
            NoLoopSyswrite($fh, $NoRelaying."\r\n",0);
            $this->{prepend}="[InternalAddress]";
            mlog($fh,"invalid remote sender for internal address: $uh");
            pbAdd($fh,$this->{ip},'iaValencePB',"internaladdress:$uh") ;
            $Stats{internaladdresses}++;
            delayWhiteExpire($fh);
            done($fh);
            return;
        }

        $this->{spamMaxScore} ||= 0;
        my %slHash;
        for (qw(spamLovers      baysSpamLovers blSpamLovers    hlSpamLovers  hiSpamLovers
                bombSpamLovers  ptrSpamLovers  mxaSpamLovers   spfSpamLovers rblSpamLovers
                uriblSpamLovers srsSpamLovers  delaySpamLovers pbSpamLovers  sbSpamLovers
                atSpamLovers    isSpamLovers))
        {
            my $oMS = $this->{spamMaxScore};
            $slHash{$_} = matchSL($uh,$_) and ($this->{spamMaxScore} = max($this->{spamMaxScore}, matchHashKey(\%{$SLscore{$_}},$uh,'0 1 1')));
            $this->{spamMaxScoreInfo} = "$uh is in $_" if $oMS < $this->{spamMaxScore};
            $slHash{'any'} ||= $slHash{$_};
            $slHash{'wo-delay'} ||= $slHash{$_} if $_ ne 'delaySpamLovers';
            $slHash{'wo-attach'} ||= $slHash{$_} if $_ ne 'atSpamLovers';
            $slHash{'wo-att-del'} ||= $slHash{$_} if $_ ne 'atSpamLovers' && $_ ne 'delaySpamLovers';
        }
        $this->{spamMaxScore} = undef if $this->{spamMaxScore} == 0;

        if ($groupSpamLovers && $this->{rcpt} && $rcptislocal && ! $this->{relayok}) {
            if ((!$this->{spamloversonly} && $slHash{'any'})
                or
                ($this->{spamloversonly} && ! $slHash{'any'})
               )
            {
                my $reply = "452 too many recipients\r\n";
                mlog($fh,"info: envelope recipient $uh rejected - spamlover mismatch with previous envelope recipients")
                  if $ValidateUserLog;
                sendque( $fh, $reply );
                return;
            }
        }

        if ($slHash{'spamLovers'}) {$this->{spamlover} |= 1} else {$this->{spamlover} |= 2};
        if ($baysSpamLoversRed && $slHash{'baysSpamLovers'}) {$this->{redsl} |= 1} else {$this->{redsl} |= 2};
        if ($slHash{'delaySpamLovers'}) {$this->{dlslre} |= 1} else {$this->{dlslre} |= 2};

        if ($rcptislocal && $slHash{'wo-att-del'} ) {
            $this->{allLoveSpam}|=1;
        } else {
            $this->{allLoveSpam}|=2;
        }
        if ($rcptislocal) {
            my $m = $slHash{'spamLovers'};
            if ($slHash{'baysSpamLovers'}  || $m) { $this->{allLoveBaysSpam}|=1 }  else { $this->{allLoveBaysSpam}|=2 }
            if ($slHash{'blSpamLovers'}    || $m) { $this->{allLoveBlSpam}|=1 }    else { $this->{allLoveBlSpam}|=2 }
            if ($slHash{'bombSpamLovers'}  || $m) { $this->{allLoveBoSpam}|=1 }    else { $this->{allLoveBoSpam}|=2 }
            if ($slHash{'ptrSpamLovers'}   || $m) { $this->{allLovePTRSpam}|=1 }   else { $this->{allLovePTRSpam}|=2 }
            if ($slHash{'mxaSpamLovers'}   || $m) { $this->{allLoveMXASpam}|=1 }   else { $this->{allLoveMXASpam}|=2 }
            if ($slHash{'hlSpamLovers'}    || $m) { $this->{allLoveHlSpam}|=1 }    else { $this->{allLoveHlSpam}|=2 }
            if ($slHash{'hiSpamLovers'}    || $m) { $this->{allLoveHiSpam}|=1 }    else { $this->{allLoveHiSpam}|=2 }
            if ($slHash{'spfSpamLovers'}   || $m) { $this->{allLoveSPFSpam}|=1 }   else { $this->{allLoveSPFSpam}|=2 }
            if ($slHash{'rblSpamLovers'}   || $m) { $this->{allLoveRBLSpam}|=1 }   else { $this->{allLoveRBLSpam}|=2 }
            if ($slHash{'atSpamLovers)'})         { $this->{allLoveATSpam}|=1 }    else { $this->{allLoveATSpam}|=2 }
            if ($slHash{'uriblSpamLovers'} || $m) { $this->{allLoveURIBLSpam}|=1 } else { $this->{allLoveURIBLSpam}|=2 }
            if ($slHash{'srsSpamLovers'}   || $m) { $this->{allLoveSRSSpam}|=1 }   else { $this->{allLoveSRSSpam}|=2 }
            if ($slHash{'delaySpamLovers'} || $m) { $this->{allLoveDLSpam}|=1 }    else { $this->{allLoveDLSpam}|=2 }
            if ($slHash{'pbSpamLovers'}    || $m) { $this->{allLovePBSpam}|=1 }    else { $this->{allLovePBSpam}|=2 }
            if ($slHash{'sbSpamLovers'}    || $m) { $this->{allLoveSBSpam}|=1 }    else { $this->{allLoveSBSpam}|=2 }
            if ($slHash{'isSpamLovers'}    || $m) { $this->{allLoveISSpam}|=1 }    else { $this->{allLoveISSpam}|=2 }
        }
        
        if ($groupSpamLovers && ! $this->{rcpt} && $rcptislocal && ! $this->{relayok}) {
            if ($slHash{'wo-delay'}) {
                $this->{spamloversonly} = 1;
            } else {
                $this->{spamloversonly} = 0;
            }
        }

        if (! $this->{whitelisted} && $whiteListedDomains && matchRE(["$this->{mailfrom},$uh"],'whiteListedDomains')) {
            $lastREmatch =~ s/,/ for /o;
            $this->{passingreason} = "whiteListedDomains '$lastREmatch'";
            $this->{whitelisted}=1;
        }

############################################ email interface ###################

        if ( $emailok )
        {
            $this->{mailfrom} = &batv_remove_tag(0,$this->{mailfrom},'');
            if(lc $u eq lc "$EmailSpam\@") {
                $this->{reportaddr} = 'EmailSpam';
  		        $this->{getline} = \&SpamReport;
                mlog( $fh, "email: spamreport", 1 ) if !($EmailErrorsModifyWhite || $EmailErrorsModifyNoP);
                mlog( $fh, "email: combined spam & whitelist report", 1 ) if $EmailErrorsModifyWhite;
                mlog( $fh, "email: combined spam & noprocessing report", 1 ) if $EmailErrorsModifyNoP;
                $Stats{rcptReportSpam}++;
                sendque($fh,"250 OK\r\n");
                return;
            } elsif(lc $u eq lc "$EmailHam\@") {
                $this->{reportaddr} = 'EmailHam';
		        $this->{getline} = \&SpamReport;
                mlog( $fh, "email: hamreport", 1 ) if !($EmailErrorsModifyWhite == 1 || $EmailErrorsModifyNoP);
                mlog( $fh, "email: combined ham & whitelist report", 1 ) if $EmailErrorsModifyWhite == 1;
                mlog( $fh, "email: combined ham & noprocessing report", 1 ) if $EmailErrorsModifyNoP;
                $Stats{rcptReportHam}++;
                sendque($fh,"250 OK\r\n");
                return;
            } elsif(lc $u eq lc "$EmailWhitelistAdd\@") {
                $this->{reportaddr} = 'EmailWhitelistAdd';
                $this->{getline}=\&ListReport;
                mlog($fh,"email whitelist addition report",1);
                $Stats{rcptReportWhitelistAdd}++;
                foreach my $ad (split(/ /o,$this->{rcpt})) {ListReportExec($ad,$this)};
                sendque($fh,"250 OK\r\n");
                return;
            } elsif(lc $u eq lc "$EmailWhitelistRemove\@") {
                $this->{reportaddr} = 'EmailWhitelistRemove';
                $this->{getline}=\&ListReport;
                mlog($fh,"email whitelist deletion report",1);
                $Stats{rcptReportWhitelistRemove}++;
                foreach my $ad (split(/ /o,$this->{rcpt})) {ListReportExec($ad,$this)};
                sendque($fh,"250 OK\r\n");
                return;
            } elsif(lc $u eq lc "$EmailRedlistAdd\@") {
                $this->{reportaddr} = 'EmailRedlistAdd';
                $this->{getline}=\&ListReport;
                mlog($fh,"email redlist addition report",1);
                $Stats{rcptReportRedlistAdd}++;
                foreach my $ad (split(/ /o,$this->{rcpt})) {ListReportExec($ad,$this)};
                sendque($fh,"250 OK\r\n");
                return;
            } elsif(lc $u eq lc "$EmailRedlistRemove\@") {
                $this->{reportaddr} = 'EmailRedlistRemove';
                $this->{getline}=\&ListReport;
                mlog($fh,"email redlist deletion report",1);
                $Stats{rcptReportRedlistRemove}++;
                foreach my $ad (split(/ /o,$this->{rcpt})) {ListReportExec($ad,$this)};
                sendque($fh,"250 OK\r\n");
                return;
            } elsif(lc $u eq lc "$EmailHelp\@") {
                $this->{reportaddr} = 'EmailHelp';
                $this->{getline}=\&HelpReport;
                mlog($fh,"email help",1);
                sendque($fh,"250 OK\r\n");
                return;
            } elsif(lc $u eq lc "$EmailAnalyze\@") {
                $this->{reportaddr} = 'EmailAnalyze';
                $this->{getline}=\&AnalyzeReport;
                sendque($fh,"250 OK\r\n");
                return;
            } elsif(lc $u eq lc "$EmailBlockReport\@" or $u =~ /^RSBM_.+?\Q$maillogExt\E\@$/i) {
                $this->{reportaddr} = 'EmailBlockReport';
                $this->{rcpt}="$u$h";
                $this->{getline}=\&BlockReport;
                mlog($fh,"blocked email report",1);
                sendque($fh,"250 OK\r\n");
                return;
            } elsif(lc $u eq lc "$EmailSpamLoverAdd\@") {
                $this->{reportaddr} = 'EmailSpamLoverAdd';
                $this->{getline}=\&ListReport;
                mlog($fh,"email spamlover addition report",1);
                foreach my $ad (split(/ /o,$this->{rcpt})) {ListReportExec($ad,$this)};
                sendque($fh,"250 OK\r\n");
                return;
            } elsif(lc $u eq lc "$EmailSpamLoverRemove\@") {
                $this->{reportaddr} = 'EmailSpamLoverRemove';
                $this->{getline}=\&ListReport;
                mlog($fh,"email spamlover deletion report",1);
                foreach my $ad (split(/ /o,$this->{rcpt})) {ListReportExec($ad,$this)};
                sendque($fh,"250 OK\r\n");
                return;
            } elsif(lc $u eq lc "$EmailNoProcessingAdd\@") {
                $this->{reportaddr} = 'EmailNoProcessingAdd';
                $this->{getline}=\&ListReport;
                mlog($fh,"email noprocessing addition report",1);
                foreach my $ad (split(/ /o,$this->{rcpt})) {ListReportExec($ad,$this)};
                sendque($fh,"250 OK\r\n");
                return;
            } elsif(lc $u eq lc "$EmailNoProcessingRemove\@") {
                $this->{reportaddr} = 'EmailNoProcessingRemove';
                $this->{getline}=\&ListReport;
                mlog($fh,"email noprocessing deletion report",1);
                foreach my $ad (split(/ /o,$this->{rcpt})) {ListReportExec($ad,$this)};
                sendque($fh,"250 OK\r\n");
                return;
            } elsif ( lc $u eq lc "$EmailBlackAdd\@" ) {
                $this->{reportaddr} = 'EmailBlackAdd';
                $this->{getline}    = \&ListReport;
                mlog( $fh, "email blacklist addition report", 1 );
                sendque( $fh, "250 OK\r\n" );
                return;
            } elsif ( lc $u eq lc "$EmailBlackRemove\@" ) {
                $this->{reportaddr} = 'EmailBlackRemove';
                $this->{getline}    = \&ListReport;
                mlog( $fh, "email blacklist deletion report", 1 );
                sendque( $fh, "250 OK\r\n" );
                return;
            } elsif ( lc $u eq lc "$EmailPersBlackAdd\@" ) {
                $this->{reportaddr} = 'EmailPersBlackAdd';
                $this->{getline}    = \&ListReport;
                mlog( $fh, "email personal blacklist addition report", 1 );
                sendque( $fh, "250 OK\r\n" );
                return;
            } elsif ( lc $u eq lc "$EmailPersBlackRemove\@" ) {
                $this->{reportaddr} = 'EmailPersBlackRemove';
                $this->{getline}    = \&ListReport;
                mlog( $fh, "email personal blacklist deletion report", 1 );
                sendque( $fh, "250 OK\r\n" );
                return;
            }
        } elsif (     $EmailInterfaceOk
                   && $this->{senderok} eq '2'
                   && $isEmailInterface
                   && (   $this->{relayok}
                       || (   $EmailSenderOK
                           && matchSL( &batv_remove_tag(0,$this->{mailfrom},''), 'EmailSenderOK' ) ))
                )
        {
            $this->{mailfrom} = &batv_remove_tag(0,$this->{mailfrom},'');
            if(lc $u eq lc "$EmailHelp\@") {
                $this->{reportaddr} = 'EmailHelp';
                $this->{getline}=\&HelpReport;
                mlog($fh,"email help",1);
                sendque($fh,"250 OK\r\n");
                return;
            } elsif(lc $u eq lc "$EmailAnalyze\@") {
                $this->{reportaddr} = 'EmailAnalyze';
                $this->{getline}=\&AnalyzeReport;
                sendque($fh,"250 OK\r\n");
                return;
            } elsif(lc $u eq lc "$EmailBlockReport\@" or $u =~ /^RSBM_.+?\Q$maillogExt\E\@$/i) {
                $this->{reportaddr} = 'EmailBlockReport';
                $this->{rcpt}="$u$h";
                $this->{getline}=\&BlockReport;
                mlog($fh,"blocked email report",1);
                sendque($fh,"250 OK\r\n");
                return;
            }
            ReturnMail($fh,$this->{mailfrom},"$base/$ReportFiles{EmailSenderNotOK}",'assp-error',\"\n");
        	$this->{getline} = \&NullFromToData;
        	&NullFromToData($fh,$l);
        	mlog($fh,"denied connection to email interface ($uh) because EmailSenderNotOK - moved to NULL-connection",1);
	        return;
        } elsif (     $EmailInterfaceOk
                   && $this->{senderok} eq '3'
                   && $isEmailInterface
                   && (   $this->{relayok}
                       || (   $EmailSenderOK
                           && matchSL( &batv_remove_tag(0,$this->{mailfrom},''), 'EmailSenderOK' ) ))
                )
        {
            $this->{mailfrom} = &batv_remove_tag(0,$this->{mailfrom},'');
        	$this->{getline} = \&NullFromToData;
        	&NullFromToData($fh,$l);
        	mlog($fh,"denied connection to email interface ($uh) because EmailSenderIgnore - moved to NULL-connection",1);
	        return;
        }
        
        $this->{rcptValidated}=$this->{rcptNonexistent}=0;

        if ($this->{addressedToSpamBucket}) {

            # accept SpamBucket addresses in every case
            $this->{rcpt}.="$uh ";
            pbTrapDelete("$uh");
        } elsif (! $this->{relayok} && matchSL([$uh,$this->{mailfrom}],'NullAddresses')) {
            mlog($fh,"connection moved to NULL-connection",1) if $ConnectionLog;
        	$this->{getline} = \&NullFromToData;
        	&NullFromToData($fh,$l);
	        return;
        } elsif (! $foreignSRS && ($LocalAddresses_Flat || $DoLDAP || ($DoVRFY && (scalar(keys %DomainVRFYMTA) || scalar(keys %FlatVRFYMTA) )))) {
            if (($this->{islocalmailaddress}) || ($this->{relayok}) && ! $rcptislocal) {
                if ( &serverIsSmtpDestination($server)) {
                    my $tuh = quotemeta($uh);
                    if ($this->{delayqueue} =~ /^$tuh | $tuh /i) {
                        $this->{rcpt}.="$uh ";
                        sendque($server, $l);
                        return;
                    } elsif ( ! Delayok($fh,"$uh")) {
                        $this->{delayqueue} .= "$uh ";
                        $this->{rcpt}.="$uh ";
                        mlog($fh,"recipient delaying queued: $uh",1) if $DelayLog >= 2;
                        sendque($server, $l);
                        return;
                    }
                }
                $this->{donotdelay} = 1;
                $this->{rcpt}.="$uh ";
                mlog($fh,"recipient accepted: $uh",1) if $this->{alllog} or $ValidateUserLog>=2;
                $this->{rcptValidated}=1;
                pbTrapDelete("$uh");
            } elsif ( exists $calist{$h} ) {
                my $uhx = $calist{$h} . "@" . $h;
                mlog( $fh, "invalid address $uh replaced with $uhx", 1 )
                  if $this->{alllog} or $ValidateUserLog >= 2;
                $this->{rcpt} .= "$uhx ";
                $this->{messagereason} = "invalid address $uh";
                pbTrapAdd( $fh, "$uh" );
                pbAdd( $fh, $this->{ip}, 'irValencePB', 'InvalidAddress' );
                $Stats{rcptNonexistent}++;
                $this->{rcptValidated} = 1;
                $l = "RCPT TO:\<$uhx\>\r\n";
                if (matchSL($uhx,'NullAddresses')) {
                	$this->{getline} = \&NullFromToData;
                	&NullFromToData($fh,$l);
                        return;
                }
            } elsif ($CatchallallISP2NULL && $this->{ispip}) {
                mlog($fh,"invalid address $uh from ISP moved to NULL-connection",1) if $this->{alllog} or $ValidateUserLog>=2;
                pbTrapAdd($fh,"$uh");
                $this->{rcptValidated}=1;
                $Stats{rcptNonexistent}++;
                $this->{getline} = \&NullFromToData;
                &NullFromToData($fh,$l);
                return;
            } elsif ($CatchAllAll) {
                my $uhx = $CatchAllAll;
                mlog( $fh, "invalid address $uh replaced with $uhx", 1 )
                  if $this->{alllog} or $ValidateUserLog >= 2;
                $this->{rcpt} .= "$uhx ";
                $this->{messagereason} = "invalid address $uhx";
                pbTrapAdd( $fh, "$uhx" );
                pbAdd( $fh, $this->{ip}, 'irValencePB', 'InvalidAddress' );
                $Stats{rcptNonexistent}++;
                $this->{rcptValidated} = 1;
                $l = "RCPT TO:\<$uhx\>\r\n";
                if (matchSL($uhx,'NullAddresses')) {
                	$this->{getline} = \&NullFromToData;
                	&NullFromToData($fh,$l);
			        return;
                }

            } else {
                $this->{prepend}="[InvalidAddress]";
                $this->{messagereason}="invalid address $uh";
                mlog($fh,"invalid address rejected: $uh") if $this->{alllog} or $ValidateUserLog;
                pbTrapAdd($fh,"$uh");
                pbAdd($fh,$this->{ip},'irValencePB','InvalidAddress');
                $Stats{rcptNonexistent}++;
                $this->{rcptNonexistent}=1;
                if ($NoValidRecipient) {
                    $reply = $NoValidRecipient."\r\n";
                    $reply =~ s/EMAILADDRESS/$u$h/go;
                } else {
                    $reply = "550 5.1.1 User unknown\r\n";
                }
                if ($reply =~ /^5/o) {
                    if ( ($this->{userTempFail} &&
                          $DoVRFY &&
                          $CanUseNetSMTP &&
                          (! ($DoLDAP && $CanUseLDAP) ||
                             ($DoLDAP && $CanUseLDAP && $LDAPoffline)
                          )
                         ) or
                         ($DoLDAP && $CanUseLDAP && $LDAPoffline &&
                          (! ($DoVRFY && $CanUseNetSMTP) ||
                             ($DoVRFY &&
                              $CanUseNetSMTP &&
                              ! $this->{userTempFail} &&
                              $uh =~ /\@([^@]*)/o &&
                              ! (&matchHashKey('DomainVRFYMTA',$1) || &matchHashKey('FlatVRFYMTA',"\@$1"))
                             )
                          )
                         )
                       )
                    {
                        $reply =~ s/^\d{3} (?:\d+\.\d+\.\d+ ?)?/450 /o;
                    }
                }

                # increment error and drop line if necessary
                if($MaxErrors && ++$this->{serverErrors} > $MaxErrors) {
                    MaxErrorsFailed($fh,
                    $reply ."421 <$myName> closing transmission\r\n",
                    "max errors (MaxErrors=$MaxErrors) exceeded -- dropping connection - after invalid address");
                    return;
                }
                sendque( $fh, $reply );
                return;
            }
        } elsif ( &serverIsSmtpDestination($server)) {
            my $tuh = quotemeta($uh);
            if ($this->{delayqueue} =~ /^$tuh | $tuh /i) {
                $this->{rcpt}.="$uh ";
                sendque($server, $l);
                return;
            } elsif (! Delayok($fh,"$uh")) {
                $this->{delayqueue} .= "$uh ";
                $this->{rcpt}.="$uh ";
                mlog($fh,"recipient delaying queued: $uh",1) if $this->{alllog} or $DelayLog>=2;
                sendque($server, $l);
                return;
            }
            $this->{rcpt}.="$uh ";
            pbTrapDelete("$uh");
        } else {
            $this->{red}="$uh in RedList" if ($Redlist{"$uh"} || $Redlist{"*\@$h"} || $Redlist{"$wildcardUser\@$h"});
            $this->{rcpt}.="$uh ";
            mlog($fh,"recipient accepted without delaying: $uh",1) if $this->{alllog} or $ValidateUserLog>=2;
            $this->{donotdelay} = 1;
            $this->{rcptValidated}=1;
            pbTrapDelete("$uh");
        }

        # update Stats
        if ($this->{rcptnoprocessing}==1) {
            $Stats{rcptUnprocessed}++;
        } elsif ($this->{addressedToSpamBucket}) {
            $Stats{rcptSpamBucket}++;
        } elsif ($this->{allLoveSpam} & 1) {
            $Stats{rcptSpamLover}++;
        } elsif ($this->{rcptValidated}) {
            $Stats{rcptValidated}++;
        } elsif ($this->{rcptNonexistent}) {
            $Stats{rcptNonexistent}++;
        } elsif ($rcptislocal) {
            $Stats{rcptUnchecked}++;
        } elsif (&Whitelist("$u$h")) {
            pbWhiteAdd($this->{ip},"whitelisted:$uh");
            $Stats{rcptWhitelisted}++;
        } else {
            $Stats{rcptNotWhitelisted}++;
        }
        $this->{numrcpt} = 0;      # calculate the total number of rcpt
        foreach (split(/ /o,$this->{rcpt})) {$this->{numrcpt}++;}
        $this->{numrcpt} = 1 if ($this->{numrcpt} == 0);
    } elsif( $l=~/^ *XEXCH50 +(\d+)/io ) {
        $this->{lastcmd} = 'XEXCH50';
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
        $this->{skipbytes}=$1;
        d("XEXCH50 b=$1");
    } elsif( $l=~/^ *(DATA)/io || $l=~/^ *(BDAT) (\d+)/io ) {
        $this->{lastcmd} = $1;
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
        if($2) {
            $this->{bdata}=$2;
        } else {
            delete $this->{bdata};
        }

############################################ relayok ###################
# check strict using of the relay port #

        if ($this->{relayok} && ++$Stats{locals} && ! $this->{isbounce}) {
            if ($RelayOnlyLocalSender && ! localmailaddress( $fh, $this->{mailfrom} ) ) {
                $this->{prepend}="[RelayAttempt]";
                mlog($fh,"relay attempt blocked for: $this->{mailfrom} - because RelayOnlyLocalSender is set to ON");
                $this->{messagereason}="relay attempt blocked for invalid local sender: $this->{mailfrom} , because RelayOnlyLocalSender is set to ON";
                pbAdd($fh,$this->{ip},'rlValencePB','RelayAttempt',1,1);
                $Stats{rcptRelayRejected}++;

                NoLoopSyswrite($fh,$NoRelaying."\r\n421 <$myName> closing transmission\r\n",0);
                done($fh);
                return;
            }
            if ($RelayOnlyLocalDomains && ! localdomainsreal($this->{mailfrom}) ) {
                $this->{prepend}="[RelayAttempt]";
                mlog($fh,"relay attempt blocked for: $this->{mailfrom} - because RelayOnlyLocalDomains is set to ON");
                $this->{messagereason}="relay attempt blocked for invalid local sender domain: $this->{mailfrom} , because RelayOnlyLocalDomains is set to ON";
                pbAdd($fh,$this->{ip},'rlValencePB','RelayAttempt',1,1);
                $Stats{rcptRelayRejected}++;

                NoLoopSyswrite($fh,$NoRelaying."\r\n421 <$myName> closing transmission\r\n",0);
                done($fh);
                return;
            }
        }
############################################ end relayok ###################

        if (defined $this->{spamMaxScore} && $ValidateUserLog && ((! $this->{relayok} && $DoPenaltyMessage) || ($this->{relayok} && $DoLocalPenaltyMessage)) ) {
            my $low = $this->{spamMaxScore} - ($this->{relayok} ? ($LocalPenaltyMessageLimit - $LocalPenaltyMessageLow) : ($PenaltyMessageLimit - $PenaltyMessageLow));
            $low ||= 1;
            mlog($fh, "the low/limit SpamLover-Score for this mail is set to $low/$this->{spamMaxScore} because recipient $this->{spamMaxScoreInfo}");
        }
        
        $this->{rcpt}=~s/\s$//o;

        $this->{numrcpt} = 0;      # calculate the total number of rcpt
        %{$this->{rcptlist}} = ();
        if ($whiteListedIPs && ! $this->{whitelisted}) {
            my $ret = matchIP( $this->{ip}, 'whiteListedIPs', $fh ,0);
            if ( $ret )
            {
                my $f = $lastREmatch ? " for 'lastREmatch'" : '';
                $this->{whitelisted}   = 1;
                $this->{passingreason} = "whiteListedIPs '$ret'$f";
            }
        }
        my $allPersWhite;
        my $removeWhite;
        foreach (split(/ /o,$this->{rcpt})) {
            $this->{numrcpt}++;
            next if $this->{rcptlist}{lc $_}++;
            next if ! $this->{relayok};
            my $w = &Whitelist($this->{mailfrom},$_);
            if (! $this->{whitelisted} && $allPersWhite != 0) {
                $allPersWhite = $w ? "$this->{mailfrom},$_" : 0;
            }
            if ($this->{whitelisted} && ! $removeWhite) {
                $removeWhite = $w ? 0 : "$this->{mailfrom},$_";
            }
        }
        $this->{numrcpt} = 1 if ($this->{numrcpt} == 0);
        if ($allPersWhite) {
            mlog($fh,"all envelope recipients are whitelisted - mail is processed as whitelisted") if $ValidateUserLog;
            $this->{whitelisted} = 1;
            $this->{passingreason} = "private-whitelistdb"
              if !$this->{passingreason};
        } elsif (! $this->{relayok} && $this->{whitelisted} && $removeWhite) {
            mlog($fh,"at least one removed private entry for an envelope recipient in whitelist ($removeWhite) - mail is no longer whitelisted") if $ValidateUserLog;
            $this->{whitelisted} = 0;
            $this->{passingreason} = ''
              if $this->{passingreason} =~ /white/o;
        }

        # drop line if no recipients left
        if ($this->{rcpt}!~/@/o) {

            # possible workaround for GroupWise bug
            if ($this->{delayed}) {
                if ($DelayError) {
                    $reply = $DelayError."\r\n";
                } else {
                    $reply = "451 4.7.1 Please try again later\r\n";
                }
                seterror($fh, $reply,1);
                mlog($fh,"DATA phase delayed",1) if $DelayLog;
                $Stats{msgDelayed}++ unless $this->{StatsmsgDelayed};
                $this->{StatsmsgDelayed} = 1;
                return;
            }
            mlog($fh,"no recipients left -- dropping connection",1) if $DelayLog || $ValidateUserLog>=2;
            $Stats{msgNoRcpt}++;

            delayWhiteExpire($fh);
            $this->{messagereason} = 'no recipients left';
            pbAdd($fh,$this->{ip},'erValencePB','NeedRecipient',0);
            seterror($fh,"503 5.5.2 Need Recipient\r\n",1);
            return;
        }
        $this->{donotdelay} ||= matchIP($this->{ip},'noDelay',$fh,0) unless $this->{relayok};
        if ($this->{noprocessing} eq '1' || ( allNP( $this->{rcpt} ) )
            || ( matchSL( $this->{mailfrom}, 'noProcessing' ) )  ) {

            $this->{noprocessing} = 1;
            $this->{myheader} .= 'X-Assp-NoProcessing: YES';
            $this->{myheader} .= " - ($this->{passingreason})" if $this->{passingreason};
            $this->{myheader} .= "\r\n";

            MaillogStart($fh);    # notify the stream logging to start logging

            &allocateMemory($fh);
            $this->{prepend}="[NoProcessing]";
            $Stats{noprocessing}++;

            $this->{getline}=\&getheader;
            mlog($fh,"message proxied without processing (except checks enabled for noprocessing mails)");
        } elsif ($this->{isbounce} && $this->{delayed}) {
            &NumRcptOK($fh,0);
            $this->{prepend} = '';
            if ($DelayError) {
                $reply = $DelayError."\r\n";
            } else {
                $reply = "451 4.7.1 Please try again later\r\n";
            }
            seterror($fh, $reply,1);

            mlog($fh,"bounce delayed",1);
            $Stats{msgDelayed}++ unless $this->{StatsmsgDelayed};
            $this->{StatsmsgDelayed} = 1;
            return;
        } elsif ( $this->{relayok} && (my $nextTry = &localFrequencyNotOK($fh)) ) {
            $nextTry = &timestring($nextTry);
            $reply = "452 too many recipients for $this->{mailfrom} in $LocalFrequencyInt seconds - please try again not before $nextTry or send a notification message to your postmaster\@LOCALDOMAIN or local administrators\r\n";
            my $mfd;
            $mfd = $1 if lc $this->{mailfrom} =~ /\@([^@]*)/o;
            $reply =~ s/LOCALDOMAIN/$mfd/go;
            seterror($fh, $reply,1);
            mlog($fh,"warning: too many recipients (more than $LocalFrequencyNumRcpt in the last $LocalFrequencyInt seconds, $this->{numrcpt} in this mail) ($this->{ip}) for $this->{mailfrom} - possible local abuse",1);
            $Stats{localFrequency}++;
            my $mfr = batv_remove_tag(0,lc $this->{mailfrom},'');
            if (! exists $localFrequencyNotify{$mfr} ||
                 $localFrequencyNotify{$mfr} < time)
            {
                $localFrequencyNotify{$mfr} = int((time + 86400) / 86400) * 86400;  # 24:00 today
                mlog($fh,"notification: too many recipients (more than $LocalFrequencyNumRcpt in the last $LocalFrequencyInt seconds, $this->{numrcpt} in this mail)($this->{ip}) for $mfr - possible local abuse",1);
            }
            return;
        } else {
            if (! $this->{donotdelay}) {                        # if there is a queued delay
                delete $this->{donotdelay};                     # and the rcpt to: phase is passed
                if ($this->{delayqueue}) {                      # and no valid recpt -> delay
                    if (!$this->{isbounce}) {
                        &NumRcptOK($fh,0);
                        $this->{prepend} = '';
                        if ($DelayError) {
                            $reply = $DelayError."\r\n";
                        } else {
                            $reply = "451 4.7.1 Please try again later\r\n";
                        }
                        chop $this->{delayqueue};
                        $this->{TestMessageScore} = 1;   # get a prepend if we delay, to have the info in rebuildspamdb
                        $this->{prepend} = '[PenaltyDelay]' if TestMessageScore($fh);        # for griplist upload
                        delete $this->{TestMessageScore};
                        my $tp = $this->{prepend};
                        $this->{prepend} = (! $this->{prepend} && ! PBOK($fh,$this->{ip})) ? '[PenaltyDelay]' : $tp;
                        delete $this->{PBOK};
                        for (split(/\s+/o,$this->{delayqueue})) {
                            mlog($fh,"recipient delayed: $_") if $this->{alllog} or $DelayLog;
                            pbTrapDelete($_);
                            $this->{prepend} = '';
                        }
                        $this->{prepend} = '';
                        seterror($fh, $reply,1);
                        delete $this->{delayqueue};
                        $Stats{msgDelayed}++ unless $this->{StatsmsgDelayed};
                        $this->{StatsmsgDelayed} = 1;
                        $this->{delayed} = 1;
                        return;
                    }
                }
            } else {
                if ($this->{delayqueue}) {
                    chop $this->{delayqueue};
                    for (split(/\s+/o,$this->{delayqueue})) {
                        mlog($fh,"queued delay removed for recipient: $_",1) if $DelayLog >= 2;
                        mlog($fh,"recipient accepted: $_",1) if $this->{alllog} or $ValidateUserLog>=2;
                        $Stats{rcptDelayed}--;
                        $Stats{rcptValidated}++;
                        pbTrapDelete($_);
                    }
                    delete $this->{delayqueue};
                }
            }
            return unless &NumRcptOK($fh,1);
            if ($runlvl0PL) {
              my $rcvd = $this->{rcvd};
              headerUnwrap($rcvd);
              my $PlData = $this->{helo}."\r\n".               # call Plugins for handshake check
                           $this->{mailfrom}."\r\n".           # in runlevel 0
                           $this->{rcpt}."\r\n".
                           $rcvd."\r\n";
              my @plres = &callPlugin($fh,0,\$PlData);
              if ($plres[0]) {  # check scoring if OK
                 @plres = MessageScorePL($fh,@plres);
              }
              if (! $plres[0]) {
# @plres = [0]result,[1]data,[2]reason,[3]plLogTo,[4]reply,[5]pltest,[6]pl
                 my $t = $plres[2] =~ /MessageScore \d+, limit \d+/io ? 'by MessageScore-check after' : 'by';
                 mlog($fh,"mail blocked $t Plugin $plres[6] - reason $plres[2]");
                 sendque($fh,"$plres[4]\r\n");
                 $this->{closeafterwrite} = 1;
                 $this->{error} = '5';
                 return;
              }
            }
            &allocateMemory($fh);
            MaillogStart($fh); # notify the stream logging to start logging
            $this->{getline}=\&getheader;
        }
    } elsif( $l=~/^ *RSET/io ) {
        $this->{lastcmd} = 'RSET';
        stateReset($fh); # reset everything
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
    } elsif( $l=~/^ *QUIT/io ) {
        $this->{lastcmd} = 'QUIT';
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
    } else {
    	my $tmp = $l ;
    	$tmp =~ s/\r|\n|\s//igo;
    	$tmp =~ /^([a-zA-Z0-9]+)/o;
    	if ($1) {
    	    $this->{lastcmd} = substr($1,0,14);
            push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
        }
    }
    if (uc($this->{lastcmd}) =~ /NOOP/o) {
        $this->{NOOPcount}++;
    } else {
        $this->{NOOPcount} = 0;
    }
    sendque($server, $l);
}
