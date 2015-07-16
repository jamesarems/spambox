#line 1 "sub main::RWLCacheAdd"
package main; sub RWLCacheAdd {
    my($myip,$status)=@_;
    return 0 unless ($RWLCacheObject);
    return 0 if !$RWLCacheInterval;
    return 0 unless $myip;
    lock($RWLCacheLock) if $lockDatabases;
    $RWLCache{$myip}=time . " $status";
}
