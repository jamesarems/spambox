#line 1 "sub main::cleanCacheDKIM"
package main; sub cleanCacheDKIM {
    d('cleanCacheDKIM');
    my $ips_before= my $ips_deleted=0;
    my $ct;
    my $t=time;
    my $maxtime = $DKIMCacheInterval*3600*24;
    while (my ($k,$v)=each(%DKIMCache)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $ips_before % 100;
        $ips_before++;

        if ($t-$v>=$maxtime) {
            delete $DKIMCache{$k};
            $ips_deleted++;
        }
    }
    mlog(0,"DKIMCache: cleaning cache finished: domains\'s before=$ips_before, deleted=$ips_deleted") if  $MaintenanceLog && $ips_before != 0;
    if ($ips_before==0) {
        %DKIMCache=();
        if ($pbdb =~ /DB:/o && ! $failedTable{DKIMCache}) {
        } else {
            &SaveHash('DKIMCache');
        }
    }
}
