#line 1 "sub main::cleanCacheMXA"
package main; sub cleanCacheMXA {
    d('cleanCacheMXA');
    my $ips_before= my $ips_deleted=0;
    my $ct;my $mx; my $mxa;
    my $t=time;
    my $maxtime = $MXACacheInterval*3600*24;
    while (my ($k,$v)=each(%MXACache)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $ips_before % 100;
        ($ct,$mx,$mxa)=split(/\s+/o,$v);

        $ips_before++;

        if ($t-$ct>=$maxtime || !$mx || !$mxa) {
            delete $MXACache{$k};
            $ips_deleted++;
        }
    }
    mlog(0,"MXACache: cleaning cache finished: IP\'s before=$ips_before, deleted=$ips_deleted") if  $MaintenanceLog && $ips_before != 0;
    if ($ips_before==0) {
        %MXACache=();
        if ($pbdb =~ /DB:/o && ! $failedTable{MXACache}) {
        } else {
            &SaveHash('MXACache');
        }
    }
}
