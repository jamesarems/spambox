#line 1 "sub main::BlackDomainOK_Run"
package main; sub BlackDomainOK_Run {
    my $fh = shift;
    my $this=$Con{$fh};
    d('BlackDomainOK');
    return 1 if $this->{relayok};
    return 1 if $this->{whitelisted}  && !$DoBlackDomainWL;
    return 1 if ($this->{noprocessing} & 1) && !$DoBlackDomainNP;
    my $tlit;
    my $ip = $this->{ip};
    $ip = $this->{cip} if $this->{ispip} && $this->{cip};

    my $slok=$this->{allLoveBlSpam}==1;
    my $DoBlackDomain = $DoBlackDomain;
    $DoBlackDomain=3 if ($switchSpamLoverToScoring && $DoPenaltyMessage && ($slok || $this->{spamlover} & 1))
                        or
                      ($switchTestToScoring && $DoPenaltyMessage && ($blTestMode || $allTestMode));

    $tlit=&tlit($DoBlackDomain);
    my ($mfd) = lc $this->{mailfrom} =~ /\@($EmailDomainRe)$/o;
    my @tocheck;
    foreach my $s ($this->{mailfrom},@{$this->{senders}}) {
        push @tocheck, $s;
        foreach my $r (keys %{$this->{rcptlist}}) {
            push @tocheck, "$s,$r";
        }
    }
    if ($blackListedDomains && (($ValidateSPF && exists $SPFCache{"0.0.0.0 $mfd"}) || matchRE(\@tocheck,'blackListedDomains',1))) {
        $this->{messagereason} = $lastREmatch ? "blacklisted domain '$lastREmatch'" : "blacklisted domain '$mfd' (by SPF-record)";
        $this->{prepend}="[BlackDomain]";
        mlog($fh,"$tlit ($this->{messagereason})") if $ValidateSenderLog && $DoBlackDomain==3 || $DoBlackDomain==2;
        pbWhiteDelete($fh,$ip);
        return 1 if $DoBlackDomain==2;
        pbAdd($fh,$ip,'blValencePB','BlacklistedDomain') ;
        return 1 if $DoBlackDomain==3;
        return 0;
    }
    return 1;
}
