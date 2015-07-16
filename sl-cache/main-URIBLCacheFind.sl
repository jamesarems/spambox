#line 1 "sub main::URIBLCacheFind"
package main; sub URIBLCacheFind {
    my $mydomain = shift;
    return 0 if !$URIBLCacheInterval;
    return 0 unless ($URIBLCacheObject);
    if (my($ct,$status,@listed)=split(/\s+/o,$URIBLCache{$mydomain})) {
        return $status;
    }
    return 0;
}
