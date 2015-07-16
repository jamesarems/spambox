#line 1 "sub main::RWLCacheFind"
package main; sub RWLCacheFind {
    my $myip = shift;
    return 0 if !$RWLCacheInterval;
    return 0 unless ($RWLCacheObject);
    return 0 unless $myip;
    if (my($ct,$status)=split(/\s+/o,$RWLCache{$myip})) {
        return $status;
    }
    return 0;
}
