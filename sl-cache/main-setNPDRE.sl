#line 1 "sub main::setNPDRE"
package main; sub setNPDRE {
    my $new=shift;
    $new||=$neverMatch; # regexp that never matches
    $new=~s/\*/\.\*/go;
    SetRE('NPDRE',"(?:$new)\$",
          $regexMod,
          'NoProcessing Domains',$_[0]);
}
