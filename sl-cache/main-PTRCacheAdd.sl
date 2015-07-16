#line 1 "sub main::PTRCacheAdd"
package main; sub PTRCacheAdd {
    my($myip,$status,$ptrdsn)=@_;
    return 0 unless ($PTRCacheObject);
    return 0 if !$PTRCacheInterval;
    return 0 unless $myip;
    return 0 if $ptrdsn =~ /localhost/io;
    $ptrdsn =~ s/\.$//o;
    lock($PTRCacheLock) if $lockDatabases;
    $PTRCache{$myip}=time . " $status $ptrdsn";
}
