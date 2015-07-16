#line 1 "sub main::cleanCacheEmergencyBlock"
package main; sub cleanCacheEmergencyBlock {
    d('cleanCacheEmergencyBlock');
    my $ips_deleted = 0;
    my $ips_before = 0;
    my $t = time - 900 ;
    while (my ($k,$v)=each(%EmergencyBlock)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $ips_before % 100;
        $ips_before++;
        if ($EmergencyBlock{$k} <= $t) {
            delete $EmergencyBlock{$k};
            $ips_deleted++;
            mlog(0,"EmergencyBlock: lifted the EMERENCY blocking for IP $k") if $MaintenanceLog;
        }
    }
    mlog(0,"EmergencyBlock: cleaning cache finished: IP\'s before=$ips_before, deleted=$ips_deleted") if  $MaintenanceLog && $ips_before > 0;
}
