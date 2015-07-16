#line 1 "sub main::setIPDWLDRE"
package main; sub setIPDWLDRE {
    my $new=shift;
    $new||=$neverMatch; # regexp that never matches
    $new=~s/\*/\.\*/go;
    SetRE('IPDWLDRE',"^(?:$new)",
          $regexMod,
          'Max IP/Domain Whitelisted Domains',$_[0]);
}
