#line 1 "sub main::MXACacheFind"
package main; sub MXACacheFind {
    my $mydomain = lc shift;
    return 0 if !$MXACacheInterval;
    return 0 unless ($MXACacheObject);
    return split( / /o, lc $MXACache{$mydomain}, 3 );
}
