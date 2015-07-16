#line 1 "sub main::pbBlackFind"
package main; sub pbBlackFind {
    my $myip = shift;
    return 0 unless ($PBBlackObject);
    my $ip = &ipNetwork( $myip, $PenaltyUseNetblocks );
    if (matchIP( $myip, 'noPB', 0, 1 ) ) {
        mlog(0,"PB: deleting(black) $myip",1) if $DoPenalty && $PenaltyLog>=2 && exists $PBBlack{$ip};
        delete $PBBlack{$myip};
        if ($ip ne $myip) {
            delete $PBBlack{$ip};
        }
        return 0;
    }
    return exists $PBBlack{$ip};
}
