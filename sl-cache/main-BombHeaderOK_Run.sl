#line 1 "sub main::BombHeaderOK_Run"
package main; sub BombHeaderOK_Run {
    my ($fh,$bd) = @_;
    my $this=$Con{$fh};
    d('BombHeaderOK');
    return 1 if $this->{BombHeaderOK};
    $this->{BombHeaderOK} = 1;
    my $ip = $this->{ip};
    $ip = $this->{cip} if $this->{ispip} && $this->{cip};
    my $helo = $this->{helo};
    $helo = $this->{ciphelo} if $this->{ispip} && $this->{ciphelo};
    my %Bombs = ();
    my $BombName;
    my $tlit;
    skipCheck($this,'sb','aa') && return 1;
    return 1 if $this->{whitelisted}  && !$bombReWL  && !$bombReWLw;
    return 1 if ($this->{noprocessing} & 1) && !$bombReNP && !$bombReNPw;
    return 1 if $this->{relayok} && !$bombReLocal && !$bombReLocalw;
    return 1 if $this->{ispip} && !$bombReISPIP && !$bombReISPIPw;
    return 1 if ($this->{mailfrom} && matchSL($this->{mailfrom},'noBombScript'));

    my $slok=$this->{allLoveBoSpam}==1;
    my $DoBombHeaderRe=$DoBombHeaderRe;
    $DoBombHeaderRe = 3 if (($switchSpamLoverToScoring && $DoPenaltyMessage && ($slok || $this->{spamlover} & 1))
                           or
                            ($switchTestToScoring && $DoPenaltyMessage && ($bombTestMode  || $allTestMode))
                           );

    $tlit=&tlit($DoBombHeaderRe);
    $this->{prepend} = '';

    our %BombSenderMailFrom = &BombWeight($fh,$this->{mailfrom},'bombSenderRe' );
    our %BombSenderIP = &BombWeight($fh,\$ip,'bombSenderRe' );
    our %BombSenderHelo = &BombWeight($fh,\$helo,'bombSenderRe' );
    our %BombCharSets = &BombWeight($fh,$bd,'bombCharSets' );
    our %BombHeaderRe = &BombWeight($fh,$bd,'bombHeaderRe' );
    our %BombSubjectRe = &BombWeight($fh,$this->{subject3},'bombSubjectRe' );
    foreach my $hBombs('BombSenderMailFrom',
                       'BombSenderIP',
                       'BombSenderHelo',
                       'BombCharSets',
                       'BombHeaderRe',
                       'BombSubjectRe'
                      )
    {
        my %hBombs = %$hBombs;
        if ($hBombs{count}) {
            $Bombs{count} += $hBombs{count};
            $Bombs{sum} += $hBombs{sum};
            if (   ($Bombs{highval} >= 0 && $hBombs{highval} >= $Bombs{highval})
                || ($Bombs{highval} <= 0 && $hBombs{highval} < $Bombs{highval} ) )
            {
                $Bombs{highnam} = $hBombs{highnam};
                $Bombs{highval} = $hBombs{highval};
                $this->{messagereason} = "$hBombs '$Bombs{matchlength}$Bombs{highnam}'";
                $this->{prepend}       = "[$hBombs]";
                $BombName = $hBombs;
            }
        }
    }

    if ($Bombs{count}) {
        my $tlit = ($DoBombHeaderRe == 1 && $Bombs{sum} < ${'bombValencePB'}[0]) ? &tlit(3) : $tlit;
        mlog($fh,"$tlit ($this->{messagereason})") if $BombLog;
        pbWhiteDelete($fh,$ip) if $Bombs{sum} > 0;
        return 1 if $DoBombHeaderRe==2;
        pbAdd($fh,$ip,calcValence($Bombs{sum},'bombValencePB'),$BombName) if ($Bombs{sum} != 0);
        return 1 if $DoBombHeaderRe==3;
        return 1 if (($Bombs{count} < $bombHeaderReMaxHits && ! $Bombs{sum}) || $Bombs{sum} < ${'bombValencePB'}[0]) ;
        return 0;
    }
    mlog($fh,"$tlit no Bomb found in header") if $BombLog >= 2;
    return 1;
}
