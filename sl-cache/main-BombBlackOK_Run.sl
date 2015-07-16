#line 1 "sub main::BombBlackOK_Run"
package main; sub BombBlackOK_Run {
  my ($fh,$bd) = @_;
  my $this=$Con{$fh};
  d('BombBlackOK');
  my $ip = $this->{ip};
  $ip = $this->{cip} if $this->{ispip} && $this->{cip};
  my %Bombs = ();
  my $subre;
  my $tlit;
  skipCheck($this,'aa','blackredone') && return 1;
  return 1 if $this->{relayok} && !$bombReLocal && !$bombReLocalw;
  return 1 if ($this->{mailfrom} && matchSL($this->{mailfrom},'noBombScript'));

  $this->{blackredone}=1;
  $this->{prepend}='';

  my $slok=$this->{allLoveBoSpam}==1;
  my $DoBlackRe = $DoBlackRe;
  $DoBlackRe = 3 if (($switchSpamLoverToScoring && $DoPenaltyMessage && ($slok || $this->{spamlover} & 1))
                   or
                     ($switchTestToScoring && $DoPenaltyMessage && ($bombTestMode  || $allTestMode))
                    );

  $tlit=&tlit($DoBlackRe);
  %Bombs = &BombWeight($fh,$bd,'blackRe' );
  if ($Bombs{count}) {
    $subre = $Bombs{highnam};
    $this->{messagereason}="BombBlack '$Bombs{matchlength}$subre'";
    $this->{prepend}="[BombBlack]";

    my $tlit = ($DoBlackRe == 1 && $Bombs{sum} < ${'blackValencePB'}[0]) ? &tlit(3) : $tlit;
    mlog($fh,"$tlit ($this->{messagereason})") if $BombLog;
    pbWhiteDelete($fh,$ip);
    return 1 if $DoBlackRe==2;
    pbAdd($fh,$ip,calcValence($Bombs{sum},'blackValencePB'),"BombBlack") if ($Bombs{sum}>0);
    return 1 if $DoBlackRe==3;
    return 1 if (($Bombs{count} < $blackReMaxHits && ! $Bombs{sum}) || $Bombs{sum} < ${'blackValencePB'}[0]);
    $Stats{bombBlack}++;
    return 0;
  }
  mlog($fh,"$tlit no Bomb found for 'bombBlack'") if ! $subre && $BombLog >= 2;
  return 1;
}
