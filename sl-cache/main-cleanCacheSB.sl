#line 1 "sub main::cleanCacheSB"
package main; sub cleanCacheSB {
    d('cleanCacheSB');
    my $ips_before= my $ips_deleted=0;
    my $t=time;
    while (my ($k,$v)=each(%SBCache)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $ips_before % 100;
        my $mSBCacheExp = $SBCacheExp;
        my ( $ct, $status, $data ) = split( "!", $v );
        my ( $ipcountry,  $orgname,  $domainname , @res) = split( /\|/o, $data ) ;
        my $forceDelete = $status == 3 && ! $ipcountry && ! $orgname;

        $ips_before++;
        $mSBCacheExp = 10 * $SBCacheExp if ($status == 2);
        if ($t-$ct>=$mSBCacheExp*3600*24 || $forceDelete) {
            delete $SBCache{$k};
            delete $WhiteOrgList{lc $domainname};
            delete $WhiteOrgList{$orgname};
            $ips_deleted++;
        }
    }

    mlog(0,"SenderBaseCache: cleaning cache finished: IP\'s before=$ips_before, deleted=$ips_deleted") if  $MaintenanceLog && $ips_before != 0;
    if ($ips_before==0) {
        %SBCache=();
        if ($pbdb =~ /DB:/o && ! $failedTable{SBCache}) {
        } else {
            &SaveHash('SBCache');
        }
    }
}
