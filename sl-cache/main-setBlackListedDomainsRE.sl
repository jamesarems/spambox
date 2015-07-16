#line 1 "sub main::setBlackListedDomainsRE"
package main; sub setBlackListedDomainsRE {
    my $new=shift;
    $new||=$neverMatch; # regexp that never matches
    $new=~s/\*/\.\*/go;
    SetRE('blackListedDomainsRE',"(?:$new)\$",
          $regexMod,
          'Blacklisted Domains',$_[0]);
}
