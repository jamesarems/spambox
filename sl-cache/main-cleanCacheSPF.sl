#line 1 "sub main::cleanCacheSPF"
package main; sub cleanCacheSPF {
    d('cleanCacheSPF');
    my $ips_before= my $ips_deleted=0;
    my $t=time;
    my $maxtime = $SPFCacheInterval*3600*24;
    while (my ($k,$v)=each(%SPFCache)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $ips_before % 100;
        my ($ct, $result, $helo)=split(/\s+/o,$v);
        $ips_before++;
        if ($t-$ct>=$maxtime or $k !~ /\s/o or $k =~ /\s$/o) {
            delete $SPFCache{$k};
            $ips_deleted++;
        }
    }
    mlog(0,"SPFCache: cleaning cache finished: IP\'s before=$ips_before, deleted=$ips_deleted") if  $MaintenanceLog && $ips_before != 0;
    if ($ips_before==0) {
        %SPFCache=();
        if ($pbdb =~ /DB:/o && ! $failedTable{SPFCache}) {
        } else {
            &SaveHash('SPFCache');
        }
    }
}
