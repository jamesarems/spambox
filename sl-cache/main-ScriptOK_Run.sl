#line 1 "sub main::ScriptOK_Run"
package main; sub ScriptOK_Run {
  my($fh,$bd)=@_;
  my $this=$Con{$fh};
  d('ScriptOK');
  my %Bombs = ();
  my $tlit;
  my $subre;
  my $DoScriptRe = $DoScriptRe;    # copy the global to local - using local from this point
  $DoScriptRe = $this->{overwritedo} if ($this->{overwritedo});   # overwrite requ by Plugin
  return 1 if $this->{ScriptOK};
  $this->{ScriptOK} = 1;
  return 1 if $this->{acceptall};
  return 1 if $this->{whitelisted}  && !$bombReWL && !$bombReWLw;
  return 1 if ($this->{noprocessing} & 1) && !$bombReNP && !$bombReNPw;
  return 1 if $this->{relayok} && !$bombReLocal && !$bombReLocalw;
  return 1 if $this->{ispip} && !$bombReISPIP && !$bombReISPIPw;
  return 1 if ($this->{mailfrom} && matchSL($this->{mailfrom},'noBombScript'));

  my $slok=$this->{allLoveBoSpam}==1;
  $DoScriptRe=3 if (($switchSpamLoverToScoring && $DoPenaltyMessage && ($slok || $this->{spamlover} & 1))
                   or
                    ($switchTestToScoring && $DoPenaltyMessage && ($scriptTestMode || $allTestMode))
                   );
  $this->{prepend}='';

  $tlit=&tlit($DoScriptRe);
  %Bombs = &BombWeight($fh,$bd,'scriptRe' );
  if ($Bombs{count}) {
    $subre = $Bombs{highnam};
    $this->{prepend}="[BombScript]";
    $this->{messagereason}=$subre;
    $this->{messagereason}="BombScript '$Bombs{matchlength}$subre'";
    my $tlit = ($DoScriptRe == 1 && $Bombs{sum} < ${'scriptValencePB'}[0]) ? &tlit(3) : $tlit;
    mlog($fh,"$tlit ($this->{messagereason})") if $BombLog;
    return 1 if $DoScriptRe==2;
    pbAdd($fh,$this->{ip},calcValence($Bombs{sum},'scriptValencePB'),"BombScript") if ($Bombs{sum}>0);
    return 1 if $DoScriptRe==3;
    return 1 if (($Bombs{count} < $scriptReMaxHits && ! $Bombs{sum}) || $Bombs{sum} < ${'scriptValencePB'}[0]);
    return 0;
  }
  mlog($fh,"$tlit no Script-Bomb found") if ! $subre && $BombLog >= 2;
  return 1;
}
