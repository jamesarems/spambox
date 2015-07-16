#line 1 "sub main::cleanCacheBackDNS"
package main; sub cleanCacheBackDNS {
    d('cleanCacheBackDNS');
    my $ips_before= my $ips_deleted=0;
    my $t=time;
    my $ct;
    my $status;
    my $maxtime = $BackDNSInterval*3600*24;
    while (my ($k,$v)=each(%BackDNS)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $ips_before % 100;
        ($ct,$status)=split(/\s+/o,$v);
        $ips_before++;
        if ($t-$ct>=$maxtime) {
            delete $BackDNS{$k};
            $ips_deleted++;
        }
    }
    mlog(0,"BackDNS: cleaning cache finished: IP\'s before=$ips_before, deleted=$ips_deleted") if  $MaintenanceLog && $ips_before != 0;
    if ($ips_before==0) {
        %BackDNS=();
        if ($pbdb =~ /DB:/o && ! $failedTable{BackDNS}) {
        } else {
            &SaveHash('BackDNS');
        }
    }
    &cleanCacheBackDNS2();
}
