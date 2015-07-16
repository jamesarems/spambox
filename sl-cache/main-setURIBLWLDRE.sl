#line 1 "sub main::setURIBLWLDRE"
package main; sub setURIBLWLDRE {
    my $new=shift;
    $new||=$neverMatch; # regexp that never matches
    $new=~s/\*/\.\*/go;
    SetRE('URIBLWLDRE',"^(?:$new)\$",
          $regexMod,
          'Whitelisted URIBL Domains',$_[0]);
}
