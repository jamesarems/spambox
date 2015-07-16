#line 1 "sub main::cleanCacheSSLfailed"
package main; sub cleanCacheSSLfailed {
    d('cleanCacheSSLfailed');
    my $ips_before= my $ips_deleted=0;
    my $ct;
    my $t=time;
    while (my ($k,$v)=each(%SSLfailed)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $ips_before % 100;
        $ips_before++;

        if ($t-$v>=43200) {   # 3600*12
            delete $SSLfailed{$k};
            $ips_deleted++;
        }
    }
    mlog(0,"SSLfailedCache: cleaning cache finished: IP\'s before=$ips_before, deleted=$ips_deleted") if  $MaintenanceLog && $ips_before > 0;
    if ($ips_before==0) {
        %SSLfailed=();
    }
}
