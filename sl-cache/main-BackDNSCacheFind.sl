#line 1 "sub main::BackDNSCacheFind"
package main; sub BackDNSCacheFind {
    my $myip = shift;
    return 0 if !$BackDNSInterval;
    return 0 unless ($BackDNSObject);
    return 0 unless $myip;
    if (my($ct,$status)=split(/\s+/o,$BackDNS{$myip})) {
        return $status;
    }
    if (my($ct,$status)=split(/\s+/o,$BackDNS2{$myip})) {
        return $status;
    }
    return 0;
}
