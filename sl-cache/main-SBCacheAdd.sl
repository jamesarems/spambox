#line 1 "sub main::SBCacheAdd"
package main; sub SBCacheAdd {
    my ( $myip, $status, $data ) = @_;
    return if !$SBCacheExp;
    return if !$SBCacheObject;
    return 0 unless $myip;
    return 0 if $myip =~ /$IPprivate/o;
    
    my ( $ipcountry, $orgname, $domainname, $blacklistscore, $hostname_matches_ip, $cidr, $hostname ) = split( /\|/o, $data );
    if ($myip =~ /^$IPv4Re$/o) {
        $cidr ||= (32 - $PenaltyUseNetblocks * 8);
        $cidr = 8 if $cidr < 8;
        $cidr = 32 if $cidr > 32;
    } elsif ($myip =~ /^$IPv6Re$/o) {
        $cidr ||= (128 - $PenaltyUseNetblocks * 32);
        $cidr = 32 if $cidr < 32;
        $cidr = 128 if $cidr > 128;
    } else {
        mlog(0,"error: SBCacheAdd - IP-address error $myip - $data");
        return 0;
    }
    my $t = time;
    {
    lock($SBCacheLock) if $lockDatabases;
    $SBCache{ ipNetwork($myip,$cidr)."/$cidr" } = "$t!$status!$data";
    }
    if ($status == 2 && $domainname && $orgname) {
        $WhiteOrgList{lc $domainname} = $orgname if ($DoOrgWhiting == 1);
    } else {
        delete $WhiteOrgList{lc $domainname} if $domainname;
    }
    return;
}
