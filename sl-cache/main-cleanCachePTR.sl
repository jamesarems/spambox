#line 1 "sub main::cleanCachePTR"
package main; sub cleanCachePTR {
    d('cleanCachePTR');
    my $ips_before = my $ips_deleted=0;
    my $t=time;
    my $ct;my $status;my $dns; my $newvrfy;
    my $maxtime = $PTRCacheInterval*3600*24;
    my $maxNoPTRtime = 4*3600;  # max 4 hours for no PTR
    while (my ($k,$v)=each(%PTRCache)) {
       &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $ips_before % 100;
       ($ct,$status,$dns)=split(/\s+/o,$v);

        $ips_before++;
        $ct = $t-$ct;
        if ($ct >= $maxtime || ($status == 1 && $ct >= $maxNoPTRtime) || $dns =~ /localhost/io) {
            delete $PTRCache{$k};
            $ips_deleted++;
            next;
        }
        if ($status == 0) {   # still not verfied against valid and invalid RE
            $newvrfy++;
            if ($dns =~ /$validPTRReRE/) {
                PTRCacheAdd($k,2,$dns);
            } elsif ($dns =~ /$invalidPTRReRE/) {
                PTRCacheAdd($k,3,$dns);
            } else {
                PTRCacheAdd($k,2,$dns);
            }
        }
    }
    mlog(0,"PTRCache: cleaning cache finished: IP\'s before=$ips_before, deleted=$ips_deleted, verfied=$newvrfy") if $MaintenanceLog && $ips_before != 0;
    if ($ips_before==0) {
        %PTRCache=();
        if ($pbdb =~ /DB:/o && ! $failedTable{PTRCache}) {
        } else {
            &SaveHash('PTRCache');
        }
    }
}
