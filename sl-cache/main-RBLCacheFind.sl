#line 1 "sub main::RBLCacheFind"
package main; sub RBLCacheFind {
    my $ip = shift;
    return if !$RBLCacheExp;
    return unless ($RBLCacheObject);
    return if $ip =~ /$IPprivate/o;
    
	my $t = time;
	my $ct;
    my $datetime;
    my $status;
    my @sp;
    if ( ( $ct, $datetime, $status, @sp ) = split( / /o, $RBLCache{$ip} ) ) {
        if (($status != 1 && $status != 2) || $t - $ct >= $RBLCacheExp * 3600 ) {
            delete $RBLCache{$ip};
            return 0;
        }
        return $status;
    }
    return 0;
}
