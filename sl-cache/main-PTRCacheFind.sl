#line 1 "sub main::PTRCacheFind"
package main; sub PTRCacheFind {
    my $myip = shift;
    return if !$PTRCacheInterval;
    return unless ($PTRCacheObject);
    return unless $myip;
    if ( my ( $ct, $status, $ptrdsn) = split( / /o, $PTRCache{$myip} ) ) {
        $ptrdsn =~ s/\.$//o;
        return wantarray ? ( $ct, $status, $ptrdsn) : $status;
    }
    return;
}
