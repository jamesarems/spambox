#line 1 "sub main::SPFCacheAdd"
package main; sub SPFCacheAdd {
    my ( $myip, $result, $domain, $helo ) = @_;
    return if !$SPFCacheInterval;
    return unless ($SPFCacheObject);
    return unless $domain;
    lock($SPFCacheLock) if $lockDatabases;
    $SPFCache{"$myip $domain"} = time . lc " $result $helo";
}
