#line 1 "sub main::LocalAddressOK"
package main; sub LocalAddressOK {
    my $fh = shift;
    my $this = $Con{$fh};
    d('LocalAddressOK');
    $this->{islocalmailaddress} = 0;
    
    if (($this->{relayok} and &batv_remove_tag(0,$this->{mailfrom},'') =~ /$BSRE/) or  # a bounce mail from a internal MTA
         &localmailaddress($fh,$this->{mailfrom})) {

        $this->{islocalmailaddress} = 1;
    }
    return $this->{islocalmailaddress};
}
