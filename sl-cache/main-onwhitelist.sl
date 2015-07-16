#line 1 "sub main::onwhitelist"
package main; sub onwhitelist {
    my($fh,$ba)=@_;
    d('onwhitelist');
    my $this = $Con{$fh};
    return $this->{whitelisted} if $this->{onwhitelistwasrun};
    $this->{onwhitelistwasrun} = 1;
    my $fm = my $adr = batv_remove_tag(0,lc $this->{mailfrom},'');
    $this->{prepend} = '';
    
    my $whitelisted;
    return 0 unless $adr; # don't add to the whitelist unless there's a valid envelope -- prevent bounced mail from adding to the whitelist
    if (! $this->{red} && $redRe && $$ba=~/($redReRE)/) {
        $this->{red} = lc($1||$2);
        mlogRe($fh,$this->{red},'redRe','redlisting');
    }
    if (! $this->{red} && $Redlist{$adr}) {
        mlogRe($fh,$adr,'Redlist','redlisting');
        $this->{red} = "$adr in Redlist";
    }

    my %senderlist = ();
    if (! $this->{relayok}) {
        $senderlist{$adr}=1;
        if(! $NotGreedyWhitelist || $NotGreedyWhitelist == 2) {
            if (scalar @{$this->{senders}}) {
                map { $senderlist{$_}=1 } @{$this->{senders}};
            } else {
                while ($$ba =~ /($HeaderNameRe):($HeaderValueRe)/igos) {
                    my $s = $2;
                    next if $1 !~ /^(?:from|sender|reply-to|errors-to|list-\w+)$/io;
                    &headerUnwrap($s);
                    if ($s =~ /($EmailAdrRe\@$EmailDomainRe)/io) {
                        $s = batv_remove_tag(0,$1,'');
                        $senderlist{lc $s}=1;
                    }
                }
            }
        }
        foreach my $adr (keys %senderlist) {
            if ($adr && $Redlist{$adr}) {
                mlog($fh,"redlisted: $adr - not white");
                return 0;
            }
        }
        my $notAllWhite;
        foreach my $ad (split(/\s+/o,lc $this->{rcpt})) {
            my $skipPrivat;
            if (localdomains($ad) && matchRE([$ad],'whiteListedDomains',1)) {
               $skipPrivat = 1;
               mlog(0,"error: the local address '$ad' matches a definition in 'whiteListedDomains' - please remove this entry");
            }
            foreach my $adr (keys %senderlist) {
                next if $adr eq '' || localmail($adr);
                if($whiteListedDomains && matchRE([$adr],'whiteListedDomains',1)) {
                    d('whiteListedDomains ' . $lastREmatch);
                    $whitelisted=1;
                    mlog($fh,"Whitelisted sender Domain: $lastREmatch");
                } elsif($whiteListedDomains && ! $skipPrivat && matchRE(["$adr,$ad"],'whiteListedDomains',1)) {
                    d('whiteListedDomains ' . $lastREmatch);
                    $whitelisted=1;
                    $lastREmatch =~ s/,/ for /o;
                    mlog($fh,"Whitelisted sender Domain: $lastREmatch");
                } elsif(&Whitelist($adr,$ad)) {
                    d('on whitelist ' . $adr);
                    $whitelisted=1;
                    mlog($fh,"Whitelisted sender address: $adr for recipient $ad");
                } elsif ($NotGreedyWhitelist == 2) {
                    mlog($fh,"found NOT whitelisted sender address: $adr");
                    $notAllWhite = 1;
                }
            }
        }
        if ($notAllWhite) {
            mlog($fh,"not all senders addresses are whitelisted - not white (NotGreedyWhitelist)") if $whitelisted;
            $whitelisted='';
        }
        @{$this->{senders}} = keys %senderlist; # used for finding blacklisted domains
        if ($whitelisted) {
            $Stats{whites}++;
            $this->{whitelisted} = 1;
        }
    }

    # don't add to whitelist if sender is redlisted
    return $whitelisted if $this->{red};
    # don't add to whitelist if sender is not local but required
    return $whitelisted if $WhitelistLocalOnly && !$this->{relayok} || $WhitelistLocalFromOnly && ! localmail($this->{mailfrom});

    # add checks for outgoing mails
    if (! $this->{relayok}) {
        # don't add to whitelist if the mail score has reached PenaltyMessageLow
        return $whitelisted if $PenaltyMessageLow && $this->{messagescore} >= $PenaltyMessageLow;
        # don't add to whitelist if the mail has failed SPF
#        return $whitelisted if $this->{spfok} == 0;
        # don't add to whitelist if the mail has failed DKIM
#        return $whitelisted if $this->{dkimresult} eq 'fail';
    }
    
    if(! $NoAutoWhite && ($whitelisted || $this->{relayok})) {
        $this->{doNotTimeout} = time;

        # keep the whitelist up-to-date
        my %ar = ($GreedyWhitelistAdditions == 2) ? %senderlist : ();  # all
        $ar{$fm}=1 if $GreedyWhitelistAdditions;      # all or envelope
        my $count = 0;
        while ($$ba=~/($HeaderNameRe):($HeaderValueRe)/igos) {
            my $ad=$2;
            next if $1 !~ /^(?:to|cc|bcc)$/io;
            while ($ad=~/($EmailAdrRe\@$EmailDomainRe)/go) {
                my $s = $1;
                $WorkerLastAct{$WorkerNumber} = time if (++$count % 100 == 0);
                $s = batv_remove_tag(0,$s,'');
                $ar{lc $s} = 1;
            }
        }
        $count = 0;
        foreach my $ad (split(/\s+/o,lc $this->{rcpt})) {
            $WorkerLastAct{$WorkerNumber} = time if (++$count % 100 == 0);
            $ad = batv_remove_tag(0,$ad,'');
            $ar{lc $ad} = 1;
        }

        my @checkAddr = ( @{$this->{senders}} , keys(%ar) );

        if (! matchSL( \@checkAddr, 'NoAutoWhiteAdresses' )) {
            $adr = '' if ! $this->{relayok};
            $count = 0;
            foreach my $ad (keys %ar) {
                $WorkerLastAct{$WorkerNumber} = time if (++$count % 100 == 0);
                next if ! $ad || localmail($ad);
                next if $Redlist{$ad}; # don't add to whitelist if rcpt is redlisted
                next if ! $EmailAllowEqual && $ad=~/\=/o;
                next if $ad=~/^\'/o;

                #next if $whiteListedDomains && matchRE([$ad],'whiteListedDomains',1);

                mlog($fh,"Admininfo: whitelist addition: $ad - AutoWhite on sent mail by $fm",1) unless &Whitelist($ad,$adr);
                &Whitelist($ad,$adr,'add');
            }
        }
#        $this->{whitelisted} = 1;
        delete $this->{doNotTimeout} if (! $smtpIdleTimeout || time - $this->{doNotTimeout} < $smtpIdleTimeout - 10);
        return 1;
    }
    return 0;
}
