#line 1 "sub main::ForgedHeloOK_Run"
package main; sub ForgedHeloOK_Run {
  my $fh = shift;
  my $this=$Con{$fh};
  d('ForgedHeloOK');
  my $tlit;

  my $helo = $this->{ciphelo} ? $this->{ciphelo}: $this->{helo};
  return 1 if $heloBlacklistIgnore && $helo =~ /$HBIRE/;
  my $ip = $this->{ip};
  $ip = $this->{cip} if $this->{ispip} && $this->{cip};

  return 1 if $this->{forgedhelodone} eq "$ip $helo";
  $this->{forgedhelodone} = "$ip $helo";
  my ($to) = $this->{rcpt} =~ /(\S+)/o;
  skipCheck($this,'ro','aa','co','nohelo','ispcip') && return 1;
  return 1 if $DoFakedWL && ($this->{whitelisted} || &Whitelist($this->{mailfrom},$to));
  return 1 if ($noProcessing && $DoFakedNP && $this->{mailfrom}=~/$NPREL/ );

  $tlit=&tlit($DoFakedLocalHelo);

  (my $literal)=$helo=~/\[?($IPRe)\]?/o; # IP literal

  if ($localDomains && $helo =~ /$LDRE/ ||
      lc($helo) eq 'localhost' ||
      $localhostname && lc($helo) eq lc($localhostname) ||
      $myServerRe && $helo =~ /$LHNRE/ ||
      $literal && $literal =~ /$IPloopback/o ||
      $literal && $myServerRe && $literal =~ /$LHNRE/ ||
      $literal && lc($literal) eq lc($localhostip))
  {

   	$this->{prepend}='[ForgedHELO]' ;
  	$this->{prepend}.="$tlit" if $DoFakedLocalHelo>=2;
  	$this->{messagereason}="forged Helo: '$helo'";
	mlog($fh,"$tlit ($this->{messagereason})") if $ValidateSenderLog;
    delayWhiteExpire($fh);
    pbWhiteDelete($fh,$ip);
    return 1 if  $DoFakedLocalHelo==2;
    pbWhiteDelete($fh,$ip);

    pbAdd($fh,$ip,'fhValencePB','ForgedHELO');
    return 1 if  $DoFakedLocalHelo==3;
    $Stats{forgedHelo}++;
    return 0;
  }
  return 1;
}
