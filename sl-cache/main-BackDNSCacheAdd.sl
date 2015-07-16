#line 1 "sub main::BackDNSCacheAdd"
package main; sub BackDNSCacheAdd {
    my($myip,$status)=@_;
    return 0 if !$BackDNSInterval;
    return 0 unless ($BackDNSObject);
    return 0 unless $myip;
    lock($BackDNSLock) if $lockDatabases;
    $BackDNS{$myip}=time . " $status";
}
