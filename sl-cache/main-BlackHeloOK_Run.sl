#line 1 "sub main::BlackHeloOK_Run"
package main; sub BlackHeloOK_Run {
    my($fh,$fhelo)=@_;
    my $this=$Con{$fh};
    d('BlackHeloOK');
    skipCheck($this,'ro','co','nohelo','ispcip') && return 1;
    return 1 if $this->{whitelisted} && !$DoHeloWL;
    return 1 if ($this->{noprocessing} & 1) && !$DoHeloNP;

    my $tlit;
    my $ip = $this->{ip};
    $ip = $this->{cip} if $this->{ispip} && $this->{cip};
    my $helo = lc($fhelo);
    $helo = lc($this->{ciphelo}) if $this->{ispip} && $this->{ciphelo};

    return 1 if ! $HeloBlackObject;
    my $val = $HeloBlack{$helo};
    return 1 if $val < 1;
    return 1 if $heloBlacklistIgnore && $helo =~ /$HBIRE/;
    return 1 if (($this->{rwlok} && ! $this->{cip}) or ($this->{cip} && pbWhiteFind($this->{cip})));

    my $slok=$this->{allLoveHlSpam}==1;
    $slok = 0 if allSH($this->{rcpt},'hlSpamHaters');
    my $useHeloBlacklist = $useHeloBlacklist;
    $useHeloBlacklist=3 if $switchSpamLoverToScoring && $DoPenaltyMessage && ($slok || $this->{spamlover} & 1);
    $useHeloBlacklist=3 if $switchTestToScoring && $DoPenaltyMessage && ($hlTestMode || $allTestMode);

    $tlit= &tlit($useHeloBlacklist);
    $this->{prepend}="[BlackHELO]";
    $this->{messagereason}="blacklisted HELO '$helo' - weight $HeloBlack{$helo}";
    mlog($fh,"$tlit ($this->{messagereason})") if $ValidateSenderLog && $useHeloBlacklist==3 || $useHeloBlacklist==2;
    delayWhiteExpire($fh);
    return 1 if $useHeloBlacklist==2;
    my $factor = int($val/ 4);
    $factor ||= 1;
    $factor = 3 if $factor > 3;
    pbAdd($fh,$ip,([${'hlValencePB'}[0] * $factor,${'hlValencePB'}[1] * $factor]),"BlacklistedHelo");
    return 1 if $useHeloBlacklist==3;
    return 0;
}
