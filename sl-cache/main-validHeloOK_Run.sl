#line 1 "sub main::validHeloOK_Run"
package main; sub validHeloOK_Run {
    my ( $fh, $fhelo ) = @_;
    my $this = $Con{$fh};
    d('validHeloOK');
    my $tlit;
    my $ip = $this->{ip};
    $ip = $this->{cip} if $this->{ispip} && $this->{cip};
    my $helo = $$fhelo;
    $helo = $this->{ciphelo} if $this->{ispip} && $this->{ciphelo};
    return 1 if $this->{validhelodone} eq $helo;
    $this->{validhelodone} = $helo;
    my ($to) = $this->{rcpt} =~ /(\S+)/o;
    skipCheck($this,'formathelodone','ro','nohelo','aa','ispcip') && return 1;
    return 1 if !$DoHeloWL && ($this->{whitelisted} || &Whitelist($this->{mailfrom},$to));
    return 1 if ($this->{noprocessing} & 1) && !$DoHeloNP;
    return 1 if (($this->{rwlok} && ! $this->{cip}) or ($this->{cip} && pbWhiteFind($this->{cip})));

    #return 1 if $this->{contentonly};
    return 1 if $heloBlacklistIgnore && $helo =~ /$HBIRE/;
    my $slok = $this->{allLoveHiSpam} == 1;
    my $DoValidFormatHelo = $DoValidFormatHelo;
    $DoValidFormatHelo = 3
      if (   $switchSpamLoverToScoring
          && $DoPenaltyMessage
          && ( $slok || $this->{spamlover} & 1))
        or
         (   $switchTestToScoring
          && $DoPenaltyMessage
          && ( $ihTestMode || $allTestMode ));

    if (   $DoValidFormatHelo
        && $validFormatHeloRe
        && ( $helo !~ /$validFormatHeloReRE/ ) )
    {
        $tlit = &tlit($DoValidFormatHelo);
        $this->{prepend} = "[ValidHELO]";

        $this->{messagereason} = "not valid HELO: '$helo'";
        mlog( $fh, "$tlit ($this->{messagereason})" )
          if $ValidateSenderLog && $DoValidFormatHelo == 3
              || $DoValidFormatHelo == 2;
        pbWhiteDelete( $fh , $ip );
        return 1 if $DoValidFormatHelo == 2;
        $this->{formathelodone}=1;
        pbAdd( $fh, $ip, 'ihValencePB', 'ValidHELO' );
        return 1 if $DoValidFormatHelo == 3;
        return 0;
    }
    return 1;
}
