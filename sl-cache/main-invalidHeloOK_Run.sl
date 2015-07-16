#line 1 "sub main::invalidHeloOK_Run"
package main; sub invalidHeloOK_Run {
    my ( $fh, $fhelo ) = @_;
    my $this = $Con{$fh};
    d('invalidHeloOK');
    my $tlit;
    my $helo = $$fhelo;
    $helo = $this->{ciphelo} if $this->{ispip} && $this->{ciphelo};
    my $ip = $this->{ip};
    $ip = $this->{cip} if $this->{ispip} && $this->{cip};
    return 1 if $this->{invalidhelodone} eq "$ip $helo";
    $this->{invalidhelodone} = "$ip $helo";
    skipCheck($this,'formathelodone','ro','co','nohelo','aa','ispcip') && return 1;
    return 1 if $this->{whitelisted}  && !$DoHeloWL && !$DoHeloWLw;
    return 1 if ($this->{noprocessing} & 1) && !$DoHeloNP && !$DoHeloNPw;
    return 1 if (($this->{rwlok} && ! $this->{cip}) or ($this->{cip} && pbWhiteFind($this->{cip})));
    return 1 if $heloBlacklistIgnore && $helo =~ /$HBIRE/;

    #return 1 if $this->{contentonly};
    my $slok = $this->{allLoveHiSpam} == 1;
    my $DoInvalidFormatHelo = $DoInvalidFormatHelo;
    $DoInvalidFormatHelo = 3
      if (   $switchSpamLoverToScoring
          && $DoPenaltyMessage
          && ( $slok || $this->{spamlover} & 1))
       or
         (   $switchTestToScoring
          && $DoPenaltyMessage
          && ( $ihTestMode || $allTestMode ));

    my %HELOs = &BombWeight($fh,$helo,'invalidFormatHeloRe' );

    if (   $DoInvalidFormatHelo
        && $invalidFormatHeloRe
        && $HELOs{count} )
    {
		
        $this->{prepend} = "[InvalidHELO]";

        $this->{messagereason} = "invalid HELO: '$HELOs{matchlength}$helo'";
        $tlit = ($DoInvalidFormatHelo == 1 && $HELOs{sum} < ${'ihValencePB'}[0])
             ? &tlit(3)
             : &tlit($DoInvalidFormatHelo);
        mlog( $fh, "$tlit ($this->{messagereason})" )
          if $ValidateSenderLog && $DoInvalidFormatHelo == 3
              || $DoInvalidFormatHelo == 2;
        pbWhiteDelete( $fh , $ip );
        return 1 if $DoInvalidFormatHelo == 2;
        $this->{formathelodone}=1;  # do not a validHeloOK
        pbAdd( $fh, $ip, calcValence($HELOs{sum},'ihValencePB'), "InvalidHELO" )
          if $HELOs{sum} > 0;
        $this->{invalidhelofound} = 1;
        return 1 if $DoInvalidFormatHelo == 3 || $HELOs{sum} < ${'ihValencePB'}[0];
        return 0;
    }
    return 1;
}
