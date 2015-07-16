#line 1 "sub main::headerAddrCheckOK_Run"
package main; sub headerAddrCheckOK_Run {
    my $fh = shift;
    my $this = $Con{$fh};
    d('headerAdrCheckOK');

    for my $bcc ('bcc','cc','to') {
        my $BCC = uc $bcc;
        my $remove = (($bcc eq 'bcc') && $removeForeignBCC);
        if ($remove && $this->{header} =~ s/(^|\n)$bcc:(?:$HeaderValueRe)/$1/igs) {
            mlog($fh,"info: found and removed unexpected $BCC: recipient addresses in incoming mail") if $ValidateUserLog >= 2;
            $this->{nodkim} = 1;     # we have modified the header and should skip the DKIM check for this reason
        } elsif ($DoHeaderAddrCheck && ! $nolocalDomains && (my @bccRCPT = $this->{header} =~ /(?:^|\n)$bcc:($HeaderValueRe)/igs)) {
            mlog($fh,"info: checking for unexpected $BCC: recipient addresses in incoming mail") if $ValidateUserLog >= 2;
            foreach my $bc (@bccRCPT) {
                headerUnwrap($bc);
                while ($bc =~ /($EmailAdrRe\@$EmailDomainRe)/igos) {
                    my $addr = $1;
                    if ($ReplaceRecpt) {
                        my $newadr = RcptReplace($addr,batv_remove_tag('',$this->{mailfrom},0),'RecRepRegex');
                        if (lc $newadr ne lc $addr) {
                            $this->{header} =~ s/((?:^|\n)$bcc:(?:$HeaderValueRe)*?)\Q$addr\E/$1$newadr/is;
                            mlog($fh,"$BCC: - recipient $addr replaced with $newadr") if $ValidateUserLog;
                            $addr = $newadr;
                            $this->{nodkim} = 1;     # we have modified the header and should skip the DKIM check for this reason
                        }
                    }
                    next if localmailaddress($fh,$addr);

                    if (   ! $this->{whitelisted}
                        && ! ($this->{noprocessing} & 1)
                        && (&pbTrapFind($fh, $addr) || ( matchSL($addr,'spamtrapaddresses') && ! matchSL($addr,'noPenaltyMakeTraps'))))
                    {
                        $this->{prepend}="[Trap]";
                        pbWhiteDelete($fh,$this->{ip});
                        $this->{whitelisted} = '';
                        my $mf = batv_remove_tag(0,lc $this->{mailfrom},'');
                        if ( &Whitelist($mf,$addr) ) {
                    		&Whitelist($mf,$addr,'delete');
                    		mlog( $fh, "penalty trap: whitelist deletion: $this->{mailfrom}" );
                        }
                        RWLCacheAdd( $this->{ip}, 4 );  # fake RWL none
                        mlog($fh,"[spam found] penalty trap address: $addr");
                        $this->{messagereason} = "penalty trap address: $addr in $BCC:";
                        pbAdd($fh,$this->{ip},'stValencePB','penaltytrap',0) ;
                        $Stats{penaltytrap}++;
                        delayWhiteExpire($fh);
                        my $reply = "421 closing transmission - 5.1.1 User unknown: $addr\r\n";
                        if ($PenaltyTrapPolite) {
                            $reply = $PenaltyTrapPolite;
                            $reply =~ s/EMAILADDRESS/$addr/go;
                        }
                        if ($send250OK or ($this->{ispip} && $send250OKISP)) {
                            $this->{getline} = \&NullData;
                        } else {
                            sendque( $fh, $reply );
                            $this->{closeafterwrite} = 1;
                            done2($this->{friend});
                            delete $this->{friend};
                        }
                        $this->{prepend} = '';
                        return 0;
                    }

                    if (localmail($addr)) {
                        $this->{header} =~ /(?:^|\n)$bcc:(?:$HeaderValueRe)*?\Q$addr\E/is;
                        next if skipCheck($this,'aa','wl','rw','nb','nbip');
                        next if ($this->{noprocessing} & 1);
                        mlog($fh,"$BCC: - local but not valid recipient address '$addr' detected in mail header") if $ValidateUserLog;
                        pbAdd( $fh, $this->{ip}, 'irValencePB', 'InvalidAddress' );
                        next;
                    }
                    next if $bcc eq 'cc';   #cc: can be foreign
                    next if $bcc eq 'to';   #to: can be foreign

                    pbAdd($fh,$this->{ip},'rlValencePB','RelayAttempt',0);
                    $this->{prepend} = "[RelayAttempt]";
                    my $reply = "421 closing transmission - $BCC: recipient ($addr) is not local\r\n";
                    $this->{messagereason} = "relay attempt blocked for non local $BCC: recipient - $addr";
                    mlog(0,"Notice: you may set 'removeForeignBCC' to prevent this relay attempt blocking") if $ValidateUserLog;
                    $this->{spamfound} = 1;
                    if ($send250OK or ($this->{ispip} && $send250OKISP)) {
                        my $fn = $this->{maillogfilename};   # store the mail if we have to receive it
                        unless ($fn) {
                            $fn = Maillog($fh,'',6); # tell maillog what this is -> discarded.
                        }
                        $fn=' -> '.$fn if $fn ne '';
                        $fn='' if !$fileLogging;
                        my $logsub = ( $subjectLogging && $this->{originalsubject} ? " $subjectStart$this->{originalsubject}$subjectEnd" : '' );
                        mlog($fh,"[spam found] $this->{messagereason}$logsub".de8($fn),0,2);
                        $this->{getline} = \&NullData;
                    } else {
                        mlog( $fh, "[spam found] $this->{messagereason}" );
                        sendque( $fh, $reply );
                        $this->{closeafterwrite} = 1;
                        done2($this->{friend});
                        delete $this->{friend};
                    }
                    $Stats{rcptRelayRejected}++;
                    delayWhiteExpire($fh);
                    $this->{prepend} = '';
                    return 0;
                }
            }
        }
    }
    $this->{prepend} = '';
    return 1;
}
