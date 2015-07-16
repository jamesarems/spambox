#line 1 "sub main::cleanCacheDelayIPPB"
package main; sub cleanCacheDelayIPPB {
    d('cleanCacheDelayIPPB');
    my $ips_deleted = 0;
    my $ips_before = 0;
    my $t = time - 24 * 3600 ;
    while (my ($k,$v)=each(%DelayIPPB)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $ips_before % 100;
        $ips_before++;
        if ($DelayIPPB{$k} <= $t) {
            delete $DelayIPPB{$k};
            $ips_deleted++;
        }
    }
    mlog(0,"DelayIPPB: cleaning cache finished: IP\'s before=$ips_before, deleted=$ips_deleted") if  $MaintenanceLog && $ips_before > 0;
}
