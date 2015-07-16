#line 1 "sub main::cleanCacheRWL"
package main; sub cleanCacheRWL {
    d('cleanCacheRWL');
    my $ips_before= my $ips_deleted=0;
    my $t=time;
    my $ct;
    my $status;
    my $maxtime = $RWLCacheInterval*3600*24;
    while (my ($k,$v)=each(%RWLCache)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $ips_before % 100;
        ($ct,$status)=split(/\s+/o,$v);

        $ips_before++;
        if ($t-$ct>=$maxtime or $ct < 1269300000) {   # RWL has change 2010/3/23
            delete $RWLCache{$k};
            $ips_deleted++;
        }
    }
    mlog(0,"RWLCache: cleaning cache finished: IP\'s before=$ips_before, deleted=$ips_deleted") if  $MaintenanceLog && $ips_before != 0;
    if ($ips_before==0) {
        %RWLCache=();
        if ($pbdb =~ /DB:/o && ! $failedTable{RWLCache}) {
        } else {
            &SaveHash('RWLCache');
        }
    }
}
