#line 1 "sub main::pbWhiteFind"
package main; sub pbWhiteFind {
    my $myip = shift;
    return 0 if !$DoPenalty;
    return 0 unless ($PBWhiteObject);
    my $ip = &ipNetwork($myip, $PenaltyUseNetblocks );
    if ( matchIP( $myip, 'noPBwhite', 0, 1 )) {
        delete $PBWhite{$myip};
        if ($ip ne $myip) {
            delete $PBWhite{$ip};
        }
        return 0;
    }
    return exists $PBWhite{$ip} ;
}
