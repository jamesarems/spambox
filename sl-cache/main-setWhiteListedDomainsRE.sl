#line 1 "sub main::setWhiteListedDomainsRE"
package main; sub setWhiteListedDomainsRE {
    my $new=shift;
    $new||=$neverMatch; # regexp that never matches
    SetRE('whiteListedDomainsRE',"(?:$new)\$",
          $regexMod,
          'Whitelisted Domains',$_[0]);
}
