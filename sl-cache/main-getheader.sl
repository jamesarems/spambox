#line 1 "sub main::getheader"
package main; sub getheader {
    my($fh,$l)=@_;
    d('getheader');
    my $reply;
    my $done;
    my $done2;
    my $er;
    my $this=$Con{$fh};

    $l =~ s/\r?\n$/\r\n/o; # correct malformed line termination anyway
    
    if($this->{inerror} or $this->{intemperror}) {  # got 4/5xx from MTA - possibly next step after DATA
        if ($send250OK or ($this->{ispip} && $send250OKISP)) {
            mlog($fh,"info: connection is moved to NULL after MTA has sent an error reply in DATA part") if $ConnectionLog;
            $this->{getline}=\&NullData;
            NullData($fh,$l);
            return;
        }
        $this->{cleanSMTPBuff} = 1;         # delete the SMTPbuff
        $this->{header} = '';
        $this->{getline}=\&getline;
        getline($fh,$l);
        return;
    }

    $this->{header}.=$l;
    my $headerlength=length($this->{header});
    my $maxheaderlength=$HeaderMaxLength;

    if($HeaderMaxLength && $headerlength>$maxheaderlength) {
        delayWhiteExpire($fh);
        $this->{prepend}="[OversizedHeader]";
        mlog($fh,"Possible Mailloop: Headerlength ($headerlength) > $maxheaderlength");
        seterror($fh,"554 5.7.1 possible mailloop - oversized header ($headerlength)",1);
        $Stats{msgverify}++;
        return;
    }

    if (   scalar keys %MEXH
        && ! $this->{relayok}
        && ! ($this->{noprocessing} & 1)
        && ! $this->{whitelisted}
        && $l =~ /^X-(?!ASSP)/io)
    {
        my $line = $l;
        $line =~ s/\r?\n//go;
        my ($xh) = $line =~ /^($HeaderNameRe)\:/o;
        my $maxval;
        $maxval = matchHashKey(\%MEXH,$xh) if $xh;
        if ($xh && $maxval && ++$this->{Xheaders}{lc $xh} > $maxval) {
            delayWhiteExpire($fh);
            $this->{prepend}="[Max-Equal-X-Header]";
            mlog($fh,"too many equal X-header lines (MaxEqualXHeader) - ($xh: $maxval)");
            seterror($fh,"554 5.7.7 too many equal X-headers ($xh:)",1);
            $Stats{msgverify}++;
            return;
        }
    }

    if (! $this->{relayok} && ! $this->{received}) {
        $this->{received} = $l =~ /^(?:Received:)|(?:Origin(?:at(?:ing|ed))?|Source)[\s\-_]?IP:/oi;
    }

    if ($l=~/^\.?[\r\n]*$/o) {
        $done2 = $l=~/^\.[\r\n]+$/o;
        $this->{org_header} = $this->{header};
#        $this->{header} =~ s/\r?\n/\r\n/ogs;

        my $orgnp = $this->{noprocessing};
        $this->{noprocessing} = 0 if $this->{noprocessing} eq '2';  # noprocessing on message size
        $this->{headerpassed} = 1;
        $this->{skipnotspam} = 1;
        $this->{maillength} = $this->{headerlength} = $headerlength = length($this->{header});
        $this->{headerlength} -= 3 if $done2;
        $this->{headerlength} = 0 if $this->{headerlength} < 0;
        my $slok;

        &makeSubject($fh);

        if ($crashHMM && $this->{crashfh} && HMMwillPossiblyCrash($fh,\$this->{header})) {
            $this->{prepend} = '[crashAnalyzer][block]';
            my $fn = $this->{maillogfilename};
            unless ($fn) {
                $fn = Maillog($fh,'',6); # tell maillog what this is -> discarded.
            }
            $fn=' -> '.$fn if $fn ne '';
            $fn='' if !$fileLogging;
            my $logsub = ( $subjectLogging && $this->{originalsubject} ? " $subjectStart$this->{originalsubject}$subjectEnd" : '' );
            mlog($fh,"[spam found] (crash analyzer said: 'this mail will possibly crash ASSP', will no longer analyze and forward but collect the mail)$logsub".de8($fn),0,2);
            delayWhiteExpire($fh);
            $this->{getline}=\&NullData;
            $this->{header} = 'NULL';
            $this->{intemperror} = 1;
            done2($this->{friend});
            delete $this->{friend};
            $Stats{crashAnalyze}++;
            return;
        }

        if ($this->{SRSorgAddress}) {
            $this->{nodkim} = 1 if $this->{header} =~ s/$this->{SRSorgAddress}/$this->{SRSnewAddress}/gi;
        }
        
        if (! $this->{from} && $this->{header} =~ /(?:^|\n)from:($HeaderValueRe)/oi) {
            my $from = $1;
            headerUnwrap($from);
            $this->{from} = $1 if $from =~ /($EmailAdrRe\@$EmailDomainRe)/oi;
        }

        if (! $this->{relayok} && ! PersBlackOK($fh) ) {
            $this->{skipnotspam} = 0;return;
        }

        if(! &MailLoopOK($fh)) {
            $this->{prepend}="[MailLoop]";
            mlog($fh,"warning: possible mailloop - found own received header more than $detectMailLoop times");
            seterror($fh,"554 5.7.1 possible mailloop - found own received header more than $detectMailLoop times",1);
            $Stats{msgverify}++;
            return;
        }
        d('contentonly');
        if(!$this->{contentonly} && $contentOnlyRe && $this->{header}=~/($contentOnlyReRE)/) {
            mlogRe($fh,($1||$2),'contentOnlyRe','contentonly');
            pbBlackDelete($fh,$this->{ip});
            $this->{contentonly} = 1;
            $this->{ispip} = 1;
        }
        d('allLogReRE');
        if ( $allLogRe
             && ! $this->{alllog}
             && $this->{header} =~ /$allLogReRE/ )
        {
            $this->{alllog}=1;
        }
        d('isred auto');
        if ( ! $this->{red}
            && $this->{header} =~ /(auto-submitted\:|subject\:[^\r\n]*?auto\:)/io )
            # RFC 3834
        {
            mlogRe( $fh, $1, 'redRe','red-auto' );
            $this->{red} = $1;
        }
        d('isred redReRE');
        if ( ! $this->{red}
            && $redRe
            && $this->{header} =~ /($redReRE)/ ) {

            mlogRe( $fh, ($1||$2), 'redRe','redlisting' );
            $this->{red} = ($1||$2);
        }

        NotSpamTagCheck($fh);

        my $onwhite = onwhitelist( $fh, \$this->{header} );
        if (!$this->{whitelisted} && $whiteRe && $this->{header}=~/($whiteReRE)/) {
            mlogRe($fh,($1||$2),'whiteRe','whitelisting');
            $this->{whitelisted}=1;
        }
        if(!$this->{ccnever} && $ccSpamNeverRe && $this->{header}=~/($ccSpamNeverReRE)/) {
            mlogRe($fh,($1||$2),'ccSpamNeverRe','CCnever');
            $this->{ccnever}=1;
        }
        if(! $this->{noprocessing} && $npRe && $this->{header}=~/($npReRE)/)
        {
            mlogRe($fh,($1||$2),'npRe','noprocessing');
            pbBlackDelete($fh,$this->{ip});
            $this->{noprocessing} = 1;
        }
        if(!($this->{spamlover} & 1) && $SpamLoversRe && $this->{header}=~/($SpamLoversReRE)/ ) {
            mlogRe($fh,($1||$2),'SpamLoversRe','spamlovers');
            $this->{spamlover}=3;
        }

        $this->{noMSGIDsigLog} = 1;
        $this->{prepend} = '[Noprocessing]';
        if (! $this->{relayok} &&
            $DoMSGIDsig &&
            $CanUseSHA1 &&
            ! $this->{contentonly} &&
            ! $this->{isbounce} &&
            ! $this->{noprocessing} &&
            ! $this->{addressedToSpamBucket} &&
            ! $this->{red} &&
            ! $this->{msgidsigdone} &&
            &MSGIDsigCheck($fh)
           )
        {
            $this->{msgidsigdone} = 1;
            $this->{noprocessing} = 1;
            $this->{whitelisted} = 1;
            $this->{passingreason} = 'noprocessing and whitelisted - found valid Message-ID signature';
            pbBlackDelete($fh,$this->{ip});
            pbWhiteAdd($fh,$this->{ip},'valid_Message-ID_signature');
        }

        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}
        $this->{prepend} = '';
        delete $this->{noMSGIDsigLog};

        if (! $this->{isDKIM} ) {
            if ($this->{header} =~ /(DKIM|DomainKey)-Signature:/io) {
                $this->{isDKIM} = $1;
                d("isDKIM - $1-Signature");
                if ($DoDKIM && $CanUseDKIM) {
                    $this->{prepend}="[$this->{isDKIM}]";
                    $this->{skipmaillog} = 1;
                    mlog($fh,"$this->{isDKIM}-Signature found",1);
                }
            }
        }
        $this->{prepend} = '';
        if ($this->{header} =~ /Content-Type:\s*multipart\/signed\s*;|protocol\s*=\s*"?application\/(?:(?:pgp|(?:x-)?pkcs7)-signature|pkcs7-mime)/io) {
            mlog($fh,"info: SMIME/PGP message found");
            $this->{signed} = 1;
        }

        d('parse ci*');
        if ( ($this->{received} || $this->{relayok}) && $this->{ispip} && $this->{header} =~ /X-Forwarded-For: ($IPRe)/io) {
	        $this->{cipdone} = 1;
            $this->{cip} = ipv4TOipv6($1);
            my $cip = ipv6expand($1);
            my $cip2 = $1;
            my $orgHelo = $this->{helo};
	        while ( $this->{header} =~ /Received:($HeaderValueRe)/gios ) {
                my $h = $1;
                if ( $h =~ /\s+from\s+(?:([^\s]+)\s)?(?:.+?)(?:$this->{cip}|$cip|$cip2)\]?\)(.{1,80})by.{1,20}/gis ) {

                    $this->{ciphelo} = $1;
                    $this->{helo} = $1 if $1;
                    my $rhelo = $2;
                    $rhelo =~ s/\r?\n/ /go;
                    $rhelo =~ /.+?helo\s*=\s*([^\s]+)/io;
                    if ($1) {
                        $this->{ciphelo} = $1;
                        $this->{helo} = $1;
                    }
                }
            }
            if ($this->{cip} && matchIP($this->{cip},'ispip',$fh,0)) {
                delete $this->{cip};
                delete $this->{ciphelo};
                $this->{helo} = $orgHelo;
            } else {
                $this->{nohelo} = 1 if ( $this->{cip} && matchIP( $this->{cip}, 'noHelo', $fh ,0) );
                mlog( $fh, "Found X-Forwarded-For: $this->{ciphelo} ($this->{cip})", 1, 2 ) if $this->{cip};
            }
	    } elsif ( ($this->{received} || $this->{relayok}) && $this->{ispip} && $ispHostnames && !$this->{cipdone} ) {
            $this->{cipdone} = 1;
            my $orgHelo = $this->{helo};
	        while ( $this->{header} =~ /Received:($HeaderValueRe)/gios ) {
                my $h = $1;
                if ( $h =~ /\s+from\s+(?:([^\s]+)\s)?(?:.+?)($IPRe)(.{1,80})by.{1,20}($ispHostnamesRE)/gis ) {
                    my $cip = ipv6expand(ipv6TOipv4($2));
                    my $helo = $1;
                    my $rhelo = $3;
                    next if $cip =~ /$IPprivate/o;

                    $this->{cip} = $cip;
                    $this->{ciphelo} = $helo || $cip;
                    $rhelo =~ s/\r?\n/ /go;
                    $rhelo =~ /.+?helo\s*[= ]?\s*([^\s\)]+)/io;
                    $this->{ciphelo} = $1 if $1;
                }
            }
            if ($this->{cip} && matchIP($this->{cip},'ispip',$fh,0)) {
                delete $this->{cip};
                delete $this->{ciphelo};
                $this->{helo} = $orgHelo;
            } else {
                $this->{nohelo} = 1 if ( $this->{cip} && matchIP( $this->{cip}, 'noHelo', $fh ,0) );
                mlog( $fh, "Originating IP/HELO:  $this->{cip} / $this->{ciphelo}", 1, 2 ) if $this->{cip};
            }
        }
        if ($this->{cip}) {
            $this->{whitelisted} ||= 1 if matchIP( $this->{cip}, 'whiteListedIPs', $fh ,0);
            $this->{noprocessing} ||= 1 if matchIP( $this->{cip}, 'noProcessingIPs', $fh ,0);
            $this->{acceptall} |= 2 if matchIP( $this->{cip}, 'acceptAllMail', $fh ,0);   # set to 2 or 3 for cip
        }

        if ( $enhancedOriginIPDetect && $this->{received} && ! $this->{relayok} && ! $this->{noprocessing}) {
            my ($ips,$ptr,$oip) = getOriginIPs(\$this->{header},$this->{ip},$this->{cip},0,$fh);
            @{$this->{sip}} = @{$ips};
            $this->{ssip} = $oip;
            if ($oip) {
                mlog( $fh, 'info: detected IP\'s on the mail routing way: '.join(', ',@{$this->{sip}}) ) if $ConnectionLog;
                mlog( $fh, "info: detected source IP: $this->{ssip}" ) if $ConnectionLog;
            }
        }

        HeloIsGood($fh,$this->{helo});

        if (! $this->{relayok} && ! headerAddrCheckOK($fh) ) {
            $this->{skipnotspam} = 0;return;
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        if (! &FrequencyIPOK($fh)) {
            $this->{skipnotspam} = 0;return;
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        if ($this->{cipdone} && $this->{ciphelo} && $this->{cip} && ! $this->{nohelo}) {
            if( ! &IPinHeloOK($fh) && &MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}
        }

        if(! ForgedHeloOK($fh)) {
            $reply =
                      $SenderInvalidError
                      ? "$SenderInvalidError"
                      : "$SpamError";
            $reply =~ s/REASON/$this->{messagereason}/go;
            $this->{prepend}="[ForgedHELO]";
            my $he = $this->{ciphelo} ? $this->{ciphelo}: $this->{helo};
            thisIsSpam($fh,"ForgedHELO:'$he'",$forgedHeloLog,$reply,$fhTestMode,0,0);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        if(! subjectFrequencyOK($fh)) {
            my $slok=$this->{allLoveSpam}==1;
            thisIsSpam($fh,$this->{messagereason},$spamBombLog,$SpamError,$DoSameSubject == 4,$slok,0);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        if (! $this->{whitelisted} ) {
            if (! &NoSpoofingOK( $fh, 'mailfrom' ) || ($DoNoSpoofing4From && ! &NoSpoofingOK( $fh, 'from' )) ) {
                my $slok = $this->{allLoveISSpam} == 1;
                $Stats{senderInvalidLocals}++ unless $slok;
                $reply = $SenderInvalidError;
                $reply =~ s/REASON/$this->{messagereason}/go;
                thisIsSpam( $fh, "$this->{messagereason}", $spamISLog, $reply,
                    $flsTestMode, $slok, 0 );
                if ($this->{error}) {$this->{skipnotspam} = 0;return;}
            }
            if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}
        }
        if (! LocalSenderOK($fh,$this->{ip})) {
            my $slok=$this->{allLoveISSpam}==1;
            unless ($slok) {$Stats{senderInvalidLocals}++;}
            $reply=$SenderInvalidError;
            $reply =~ s/REASON/Unknown Local Sender/go;
            $this->{prepend}="[UnknownLocalSender]";
            thisIsSpam($fh,"Unknown Local Sender",$spamISLog,$reply,$DoNoValidLocalSender==4,$slok,0);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        # if RELAYOK check localdomains if approprate
        if ( $this->{relayok}
            && ! $this->{red}
            && $DoLocalSenderDomain
            && ! $this->{acceptall}
            && ! localmail( $this->{mailfrom})
            && ! $this->{isbounce} ) {

            $this->{prepend} = "[RelayAttempt]";
            NoLoopSyswrite( $fh, "530 Relaying not allowed - sender domain not local\r\n" ,0);
            $this->{messagereason} = "relay attempt blocked for unknown local sender domain";
            mlog( $fh, $this->{messagereason} );
            $Stats{rcptRelayRejected}++;
            delayWhiteExpire($fh);
            done($fh);
            return;
        }
        # if RELAYOK check localaddresses if approprate
        if ( $this->{relayok}
            && ! $this->{red}
            && $DoLocalSenderAddress
            && ! $this->{acceptall}
            && ! LocalAddressOK( $fh)
            && ! $this->{isbounce} ) {
            $this->{prepend} = "[RelayAttempt]";
            NoLoopSyswrite( $fh, "530 Relaying not allowed - local sender address unknown\r\n",0 );
            $this->{messagereason} = "relay attempt blocked for unknown local sender address";
            mlog( $fh, $this->{messagereason} );
            $Stats{rcptRelayRejected}++;
            delayWhiteExpire($fh);
            done($fh);
            return;
        }

        if (! &RWLok($fh,$this->{ip})) {
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        if (! $this->{msgid} && $this->{header}=~/\nMessage-ID:($HeaderValueRe)/sio) {
            $this->{msgid} = decodeMimeWords2UTF8($1);
            $this->{msgid}=~s/[\s>]+$//o;
            $this->{msgid}=~s/^[\s<]+//o;
        }
        
        if (! &MsgIDOK($fh)) {
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        &GRIPvalue($fh,$this->{ip});
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        if (! &FromStrictOK($fh)) {
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        # header is done

        if(!$this->{bspams} && !$this->{noprocessing} && !$this->{whitelisted} && $WhitelistOnly) {
            $this->{bspams} = 1;
            $Stats{bspams}++;
            delayWhiteExpire($fh);
            my $slok=$this->{allLoveSpam}==1;
            $this->{prepend}="[WhitelistOnly]";
            thisIsSpam($fh,"Whitelist Only",$baysSpamLog,$SpamError,$baysTestMode,$slok,1);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }

        if(! DKIMpreCheckOK($fh)) {
            delete $this->{org_header};
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        delete $this->{org_header};
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        DMARCget($fh);

        if(! SPFok($fh) ) {
            if ($this->{error}) {delete $this->{testmode};$this->{skipnotspam} = 0;return;}
        }
        delete $this->{dkimresult};
        delete $this->{testmode};
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        if (   ! $this->{whitelisted}
            && ! $this->{relayok}
            && $this->{spfok}
            && $DoOrgWhiting == 1
            && $this->{mailfrom} =~ /\@($EmailDomainRe)$/o
            && (my $org = $WhiteOrgList{lc $1}))
        {
            mlogRe($fh,($1.' - '.$org),'WhiteOrgList','whitelisting');
            $this->{whitelisted} = 1;
        }
        
        if (! &DomainIPOK($fh)) {
            $this->{skipnotspam} = 0;return;
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        if (! &SenderBaseOK($fh,$this->{ip})) {
            $this->{prepend} = '';
            my $slok=$this->{allLoveSBSpam}==1;
            unless ($slok) {$Stats{sbblocked}++;}
            $reply=$SenderInvalidError;

            $reply =~ s/REASON/$this->{messagereason}/go;
            thisIsSpam($fh,$this->{messagereason},$spamSBLog,$reply,$DoCountryBlocking == 4,$slok,0);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        if (! PBExtremeOK( $fh, $this->{ip} ) ) {
            my $slok = $this->{allLovePBSpam} == 1;
            my $er = $SpamError;
            $er = $PenaltyError if $PenaltyError;
            thisIsSpam( $fh, $this->{messagereason}, $spamPBLog, $er,($allTestMode || $pbTestMode), $slok, 1 );
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        if (! ($this->{noprocessing} & 1) && @{$this->{sip}}) {
            mlog($fh,"info: check IP's on mail route for IP-blocking") if $ConnectionLog >= 2;
            my $res = 1;
            foreach my $ip (@{$this->{sip}}) {
               $res &= PBExtremeOK( $fh, $ip , 1);
               last unless $res;
            }
            if (! $res) {
                my $slok = $this->{allLovePBSpam} == 1;
                my $er = $SpamError;
                $er = $PenaltyError if $PenaltyError;
                thisIsSpam( $fh, $this->{messagereason}, $spamPBLog, $er,($allTestMode || $pbTestMode), $slok, 1 );
                if ($this->{error}) {$this->{skipnotspam} = 0;return;}
            }
            if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}
        }

        if(! BlackDomainOK($fh)) {
            my $slok=$this->{allLoveBlSpam}==1;
            unless ($slok) {$Stats{blacklisted}++;}
            thisIsSpam($fh,$this->{messagereason},$blDomainLog,$SpamError,$blTestMode,$slok,0);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        if ( ! &RBLCacheOK($fh,$this->{ip},0) || ! &RBLok($fh,$this->{ip},0) )  {
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        if (   ! $this->{noprocessing}
            && ! ($RBLWL && $this->{whitelisted})
            && @{$this->{sip}}
        ) {
            mlog($fh,"info: check IP's on mail route for DNSBL") if $RBLLog >= 2;
            my $donerbl = $this->{rbldone};
            my $res = 1;
            my %saveRBLSP;
            my $return;
            for my $sp ('zen.spamhaus.org','pbl.spamhaus.org') {
                for my $res ('127.0.0.10','127.0.0.11') {   # skip pbl.spamhaus.org dynamic IP-ranges return codes
                    $saveRBLSP{$sp}{$res} = $rblweight{$sp}{$res}
                        if defined $rblweight{$sp}{$res} ;
                    $rblweight{$sp}{$res} = 0;
                }
            }
            foreach my $ip (@{$this->{sip}}) {
                $this->{rbldone} = 0;
                $res &= ( ! &RBLCacheOK($fh,$ip,1) || ! &RBLok($fh,$ip,1));
                if (! $res) {
                    if ($this->{error}) {$this->{skipnotspam} = 0;$return = 1;last;}
                }
            }
            for my $sp ('zen.spamhaus.org','pbl.spamhaus.org') {
                for my $res ('127.0.0.10','127.0.0.11') {   # reset pbl.spamhaus.org dynamic IP-ranges return codes to org value
                    if (defined $saveRBLSP{$sp}{$res}) {
                        $rblweight{$sp}{$res} = $saveRBLSP{$sp}{$res};
                    } else {
                        delete $rblweight{$sp}{$res};
                    }
                }
            }
            $this->{rbldone} = $donerbl;
            return if $return;
            if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}
        }

        if(! BombHeaderOK($fh,\$this->{header})) {
            my $bomblt = $bombError;
            $bomblt .= " (reason: $this->{messagereason}) " if $bombErrorReason;
            $Stats{bombSender}++;
            delayWhiteExpire($fh);
            my $slok=$this->{allLoveBoSpam}==1;
            $this->{prepend}="[BombHeader]";
            thisIsSpam($fh,"$this->{messagereason}",$spamBombLog,$bomblt,$bombTestMode,$slok,1);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        if (! invalidHeloOK($fh,\$this->{helo})) {
            my $slok=$this->{allLoveHiSpam}==1;
            unless ($slok) {$Stats{invalidHelo}++;}
            $reply=$SenderInvalidError;
            $this->{prepend}="[InvalidHELO]";
            $reply =~ s/REASON/Invalid HELO Format/go;
            thisIsSpam($fh,$this->{messagereason},$invalidHeloLog,$reply,$ihTestMode,$slok,0);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        if (! validHeloOK($fh,\$this->{helo})) {
            my $slok=$this->{allLoveHiSpam}==1;
            unless ($slok) {$Stats{invalidHelo}++;}
            $reply=$SenderInvalidError;
            $this->{prepend}="[NotValidHELO]";
            $reply =~ s/REASON/Invalid HELO Format/go;
            thisIsSpam($fh,$this->{messagereason},$invalidHeloLog,$reply,$ihTestMode,$slok,0);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        if(! BlackHeloOK($fh,$this->{helo})) {
            my $slok=$this->{allLoveHlSpam}==1;
            unless ($slok) {$Stats{helolisted}++;}
            $this->{prepend}="[BlackHELO]";
            my $helo = lc($this->{helo});
            $helo = lc($this->{ciphelo}) if $this->{ispip} && $this->{ciphelo};
            thisIsSpam($fh,"HELO-Blacklist: '$helo'",$spamHeloLog,$SpamError,($hlTestMode || $allTestMode),$slok,0);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        if (! MXAOK($fh)) {
            my $slok=$this->{allLoveMXASpam}==1;
            unless ($slok) {$Stats{mxaMissing}++;}
            $reply=$SenderInvalidError;
            $this->{prepend}="[MissingMXA]";
            $reply =~ s/REASON/Missing MX and A record/go;
            thisIsSpam($fh,"missing MX and A record",$spamMXALog,$reply,$mxaTestMode,$slok,$done);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        if (! PTROK($fh)) {
            $reply=$SenderInvalidError;
            my $slok=$this->{allLovePTRSpam}==1;
            $reply =~ s/REASON/$this->{messagereason}/go;
            thisIsSpam($fh,"$this->{messagereason}",$spamPTRLog,$reply,$ptrTestMode,$slok,0);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        if (!$this->{noprocessing} && !$this->{whitelisted} && $this->{invalidSRSBounce} && $SRSValidateBounce && !($this->{ispip}) && !($noSRS && matchIP($this->{ip},'noSRS',0,1))) {
            $this->{invalidSRSBounce} = '';
            my $slok = $this->{allLoveSRSSpam} == 1;
            $Stats{msgNoSRSBounce}++ unless $slok;
            $this->{prepend} = "[SRS]";
            $this->{messagereason} = "bounce address not SRS signed";
            pbAdd( $fh, $this->{ip}, 'srsValencePB', 'SRS_Not_Signed', 2 ) if $SRSValidateBounce !=2;
            my $tlit = tlit($SRSValidateBounce);
            mlog( $fh, "$tlit ($this->{messagereason})" ) if $SRSValidateBounce !=1;
            thisIsSpam(
                $fh, $this->{messagereason},
                $SRSFailLog, '554 5.7.5 Bounce address not SRS signed',
                $srsTestMode, $slok, 0
            ) if $SRSValidateBounce ==1;
            $this->{prepend} = '';
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
            if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}
        }

        if($this->{isbounce} && ! &BackSctrCheckOK($fh,$this->{ip})) {
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

# remove Disposition-Notification headers if needed
        if ($removeDispositionNotification && ! $this->{relayok} && ! $this->{noprocessing} &&
            $this->{header} =~ s/(?:ReturnReceipt|Return-Receipt-To|Disposition-Notification-To):$HeaderValueRe//gios
            )
        {
            $this->{maillength} = length($this->{header});
            mlog($fh,"removed Disposition-Notification headers from mail") if $ValidateSenderLog;
        }
        if ($runlvl1PL && ! $this->{runlvl1PL}) {
            $this->{runlvl1PL} = 1;
            my @plres = &callPlugin($fh,1,\$this->{header});    # call the Plugins for runlevel 1
            if ($plres[0]) {  # check scoring if OK
                @plres = MessageScorePL($fh,@plres);
            }

      # @plres = [0]result,[1]data,[2]reason,[3]plLogTo,[4]reply,[5]pltest,[6]pl
      # thisIsSpam($fh,$plres[2],$plres[3],$plres[4],$plres[5],0,$done);
            if (! $plres[0]) {
                my $slok=$this->{spamLovers}==1;
                my $t = $plres[2] =~ /MessageScore \d+, limit \d+/io ? 'by MessageScore-check after' : 'by';
                mlog($fh,"mail blocked $t Plugin $plres[6] - reason $plres[2]");
                thisIsSpam($fh,$plres[2],$plres[3],$plres[4],$plres[5],$slok,$done);
                if ($this->{error}) {$this->{skipnotspam} = 0;return;}
            }
        }
        if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}

        $this->{noprocessing} ||= $orgnp if $orgnp;

        if ( ! $this->{whitelisted} && ! ($this->{noprocessing} & 1) && $this->{addressedToSpamBucket} && ! $this->{SpamCollectAddress} && !$DoNotBlockCollect ) {
            $this->{SpamCollectAddress} = 1;
            $Stats{spambucket}++ ;
            pbWhiteDelete($fh,$this->{ip});
            $this->{messagereason}="Collect Address: $this->{addressedToSpamBucket}";
            pbAdd($fh,$this->{ip},'saValencePB','SpamCollectAddress',2);
            $this->{prepend}="[Collect]";
            delayWhiteExpire($fh);
            thisIsSpam($fh,"$this->{messagereason}",$spamBucketLog,"250 OK",0,0,0);
            if (&MsgScoreTooHigh($fh,$done)) {$this->{skipnotspam} = 0;return;}
        }

        if (! $this->{error}) {
            if ($done2) {          # we got .\r\n
                my $lHeader = length($this->{header}) - length($l);
                $lHeader = 0 if $lHeader < 0;
                $this->{header} = substr($this->{header},0,$lHeader);
                $this->{maillength} = $lHeader;
                &getbody($fh,$l);
                $this->{getline}=\&getline unless $this->{error};
            } else {
                $this->{getline}=\&getbody;
            }
        } else {
            if ($done2) {
                return if $this->{getline} eq \&getline;
                $this->{maillength} = length($this->{header}) - length($l);
                $this->{maillength} = 0 if $this->{maillength} < 0;
                &error($fh,$l);
                return;
            }
        }
    }
}
