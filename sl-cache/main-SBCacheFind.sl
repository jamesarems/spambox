#line 1 "sub main::SBCacheFind"
package main; sub SBCacheFind {
    my $myip = shift;
    return if !$SBCacheExp;
    return if !$SBCacheObject;
    return 0 unless $myip;
    my $val;
    my $cidr;
    my $ip;
    my ($max,$min) = ($myip =~ /^IPv4Re$/o) ? (32 , 8) : (128 , 32);
    for ( $cidr = $max;
          $cidr >= $min;
          $cidr--)
    {
        $ip = ipNetwork($myip,$cidr);
        last if ($val = $SBCache{"$ip/$cidr"});
    }
    return unless $val;                #ct status data                  data only
    return wantarray ? ("$ip/$cidr", split( /!/o, $val )) : [split( /!/o, $val )]->[2];
}
