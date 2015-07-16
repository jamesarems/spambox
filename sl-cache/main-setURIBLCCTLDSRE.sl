#line 1 "sub main::setURIBLCCTLDSRE"
package main; sub setURIBLCCTLDSRE {
    my $new=shift;
    SetRE('URIBLCCTLDSRE', ($new ? "(?:\\.(?:$new))\$" : $neverMatch),
          $regexMod,
          'Country Code TLDs',$_[0]);
}
