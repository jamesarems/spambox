#line 1 "sub main::cleanCacheBackDNS2"
package main; sub cleanCacheBackDNS2 {
    d('cleanCacheBackDNS2');
    my $ips_before = my $ips_deleted = 0;
    my $t=time;
    my $ct;
    my $status;
    return unless $useDB4IntCache && $CanUseBerkeleyDB;
    return unless %BackDNS2;
    
    $ips_before = $ips_deleted=0;
    my $maxtime = $BackDNSInterval*3600*24;
    while (my ($k,$v)=each(%BackDNS2)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $ips_before % 100;
        ($ct,$status)=split(/\s+/o,$v);

        $ips_before++;
        if ($t-$ct>=$maxtime) {
            delete $BackDNS2{$k};
            $ips_deleted++;
        }
    }
    mlog(0,"BackDNS2: cleaning cache finished: IP\'s before=$ips_before, deleted=$ips_deleted") if  $MaintenanceLog && $ips_before != 0;
}
