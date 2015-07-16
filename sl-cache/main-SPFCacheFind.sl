#line 1 "sub main::SPFCacheFind"
package main; sub SPFCacheFind {
    my ($myip,$domain) = @_;
    return if !$SPFCacheInterval;
    return unless ($SPFCacheObject);
    return unless $domain;
    return 0 unless $myip;
    return split( / /o, lc $SPFCache{"0.0.0.0 $domain"} ) || split( / /o, lc $SPFCache{"$myip $domain"} ) ;
}
