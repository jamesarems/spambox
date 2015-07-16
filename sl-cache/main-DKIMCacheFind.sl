#line 1 "sub main::DKIMCacheFind"
package main; sub DKIMCacheFind {
    my $domain = lc shift;
    return 0 unless $domain;
    return exists $DKIMCache{$domain};
}
