#line 1 "sub main::BombOK_Run"
package main; sub BombOK_Run {
    my($fh,$header)=@_;
    my $this=$Con{$fh};
    return 1 if $this->{bombdone} == 1;
    d('BombOK');
    my %Bombs = ();
    my $DoBombRe = $DoBombRe;    # copy the global to local - using local from this point
    $DoBombRe = $this->{overwritedo} if ($this->{overwritedo});   # overwrite requ by Plugin
    if (! $DoBombRe){
        $this->{bombdone}=1;
        return 1;
    }
    my $subre;
    my $tlit;
    my $datastart = $this->{datastart};
    my $maillength = length($$header);
    my $ofs = 0;
    $this->{prepend}=$this->{messagereason}='';

    if ($this->{bombdone} eq 'PL') {     # if called from plugins
        $datastart = 1;
        $ofs = 1;
        $this->{bombdone}=1;
    }

    if (!$this->{whitelisted} && $whiteRe && $$header=~/($whiteReRE)/) {
        mlogRe($fh,($1||$2),'whiteRe','whitelisting');
        $this->{whitelisted}=1;
    }

    if(!$this->{spamlover} & 1 && $SpamLoversRe  && substr($$header, $datastart - 1, $maillength - $datastart + $ofs) =~ /($SpamLoversReRE)/ ) {
        mlogRe($fh,($1||$2),'SpamLoversRe','spamlovers');
        $this->{spamlover}=3;
    }

    %Bombs = $DoTestRe ? &BombWeight($fh,$header,'testRe' ) : ();
    if ($Bombs{count}) {
        $subre = $Bombs{highnam};
        mlogRe($fh,$subre,'testRe','TestRegex');
    }

    if ($this->{mailfrom} && matchSL($this->{mailfrom},'noBombScript') ) {
        return 1;}

    $tlit = &tlit(3);
    %Bombs = &BombWeight($fh,$header,'bombSuspiciousRe');
    if ($Bombs{count}) {
        $subre = $Bombs{highnam};
        $this->{messagereason}="BombSuspicious: '$Bombs{matchlength}$subre'";
        pbAdd($fh,$this->{ip},calcValence($Bombs{sum},'bombSuspiciousValencePB'),'bombSuspiciousRe');
    } else {
        mlog($fh,"$tlit no Bomb found for 'bombSuspiciousRe'") if $bombSuspiciousRe && $BombLog >= 2;
    }
    return 1 if $this->{acceptall};
    return 1 if $this->{whitelisted} && !$bombReWL  && !$bombReWLw;
    return 1 if ($this->{noprocessing} & 1) && !$bombReNP && !$bombReNPw;
    return 1 if $this->{relayok} && !$bombReLocal && !$bombReLocalw;
    return 1 if $this->{ispip} && !$bombReISPIP && !$bombReISPIPw;
    my $slok=$this->{allLoveBoSpam}==1;

    $DoBombRe = 3 if (($switchSpamLoverToScoring && $DoPenaltyMessage && ($slok || $this->{spamlover} & 1))
                   or
                      ($switchTestToScoring && $DoPenaltyMessage && ($bombTestMode || $allTestMode))
                     );
    $this->{messagereason} = '';

    $tlit=&tlit($DoBombRe);
    %Bombs = &BombWeight($fh,$header,'bombDataRe');
    if ($Bombs{count}) {
        $subre = $Bombs{highnam};
        $this->{messagereason} .= '  ' if $this->{messagereason};
        $this->{messagereason}.="BombData: '$Bombs{matchlength}$subre'";
        $this->{prepend}.='[BombData]';

        my $tlit = ($DoBombRe == 1 && $Bombs{sum} < ${'bombValencePB'}[0]) ? &tlit(3) : $tlit;
        mlog($fh,"$tlit (BombData  '$Bombs{matchlength}$subre')") if $BombLog;
        pbWhiteDelete($fh,$this->{ip}) if $Bombs{sum} > 0;
        pbAdd($fh,$this->{ip},calcValence($Bombs{sum},'bombValencePB'),"BombData") if ($DoBombRe!=2);
        return 0 if ($DoBombRe == 1 && (($Bombs{count} >= $bombDataReMaxHits && ! $Bombs{sum}) || $Bombs{sum} >= ${'bombValencePB'}[0]));
    } else {
        mlog($fh,"$tlit no Bomb found for 'bombDataRe'") if $bombDataRe && $BombLog >= 2;
    }
    if ($ofs == 1) {  # called from plugin - skip the next check - we have already done it before
        return 1;
    }
    %Bombs = &BombWeight($fh,$header,'bombRe' );
    if ($Bombs{count}) {
        $subre = $Bombs{highnam};
        $this->{messagereason} .= '  ' if $this->{messagereason};
        $this->{messagereason}.="bombRe: '$Bombs{matchlength}$subre'";
        $this->{prepend}.='[bombRe]';

        my $tlit = ($DoBombRe == 1 && $Bombs{sum} < ${'bombValencePB'}[0]) ? &tlit(3) : $tlit;
        mlog($fh,"$tlit (bombRe '$Bombs{matchlength}$subre')") if $BombLog;
        pbWhiteDelete($fh,$this->{ip}) if $Bombs{sum} > 0;
        pbAdd($fh,$this->{ip},calcValence($Bombs{sum},'bombValencePB'),"bombRe") if ($Bombs{sum} != 0 && $DoBombRe!=2);
        return 0 if ($DoBombRe == 1 && (($Bombs{count} >= $bombReMaxHits && ! $Bombs{sum}) || $Bombs{sum} >= ${'bombValencePB'}[0]));
    } else {
        mlog($fh,"$tlit no Bomb found for 'bombRe'") if $bombRe && $BombLog >= 2;
    }
# bombCharSets in MIME parts
    %Bombs = &BombWeight($fh, $header,'bombCharSets' );
    if ($Bombs{count}) {
        $subre = $Bombs{highnam};
        $this->{messagereason} .= '  ' if $this->{messagereason};
        $this->{messagereason}.="BombCharSets: '$Bombs{matchlength}$subre'";
        $this->{prepend}.='[BombCharSets]';

        my $tlit = ($DoBombRe == 1 && $Bombs{sum} < ${'bombValencePB'}[0]) ? &tlit(3) : $tlit;
        mlog($fh,"$tlit (BombCharSets '$Bombs{matchlength}$subre')") if $BombLog;
        pbWhiteDelete($fh,$this->{ip}) if $Bombs{sum} > 0;
        pbAdd($fh,$this->{ip},calcValence($Bombs{sum},'bombValencePB'),"BombCharSets") if ($Bombs{sum} != 0 && $DoBombRe!=2);
        return 0 if ($DoBombRe==1 && (($Bombs{count} >= $bombReMaxHits && ! $Bombs{sum}) || $Bombs{sum} >= ${'bombValencePB'}[0]));
    } else {
        mlog($fh,"$tlit no Bomb found for 'bombCharSets'") if $bombCharSets && $BombLog >= 2;
    }
    return 1;
}
