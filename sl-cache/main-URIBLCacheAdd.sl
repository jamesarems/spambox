#line 1 "sub main::URIBLCacheAdd"
package main; sub URIBLCacheAdd {
    my($mydomain,$status,$mylisted)=@_;
    $mylisted = ' '. $mylisted if $mylisted;
    return 0 if !$URIBLCacheInterval;
    return 0 if $status==2 && !$URIBLCacheIntervalMiss;
    lock($URIBLCacheLock) if $lockDatabases;
    $URIBLCache{$mydomain}=time . " $status$mylisted";
}
