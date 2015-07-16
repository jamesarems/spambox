#line 1 "sub main::LocalSenderOK_Run"
package main; sub LocalSenderOK_Run {
    my ( $fh, $ip ) = @_;

    my $this = $Con{$fh};
    d('LocalSenderOK');
    my $tlit;
    return 1 if $this->{localsenderdone};
    $this->{localsenderdone} = 1;
    skipCheck($this,'sb','np','ro','ispip','aa') && return 1;

    return 1 if ! localmail( $this->{mailfrom} );
    
    #enforce valid local mailfrom

    my $mf = &batv_remove_tag(0,$this->{mailfrom},'');

    $tlit = &tlit($DoNoValidLocalSender);

    $this->{islocalmailaddress} = 0;

  if(matchSL($mf,'LocalAddresses_Flat') ) {
    $this->{islocalmailaddress} = 1;
  } else {
# Need another check?

# check sender against LDAP or VRFY ?
      $this->{islocalmailaddress} = &localmailaddress($fh,$mf)
          if (($DoLDAP && $CanUseLDAP) or
              ($CanUseNetSMTP && $DoVRFY &&
               $mf =~ /^([^@]*@)([^@]*)$/o &&
               (&matchHashKey('DomainVRFYMTA',lc $2) or &matchHashKey('FlatVRFYMTA',lc "\@$2"))));
  }
  if (!$this->{islocalmailaddress}) {
    $this->{prepend} = "[UnknownLocalSender]";
    mlog($fh,"$tlit (Invalid Local Sender '$mf')") if $ValidateSenderLog && ($DoNoValidLocalSender==3 || $DoNoValidLocalSender==2);
    return 1 if ($DoNoValidLocalSender==2);
    delayWhiteExpire($fh);
    pbWhiteDelete($fh,$this->{ip});
    pbAdd($fh,$this->{ip},'flValencePB','InvalidLocalSender');
    return 1 if  $DoNoValidLocalSender==3;
    return 0;
  }
  return 1;
}
