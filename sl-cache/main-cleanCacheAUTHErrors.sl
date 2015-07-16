#line 1 "sub main::cleanCacheAUTHErrors"
package main; sub cleanCacheAUTHErrors {
    d('cleanCacheAUTHErrors');
    my $i = 0;
    while (my ($k,$v)=each(%AUTHErrors)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $i % 100;
        if (--$AUTHErrors{$k} <= 0) {
            delete $AUTHErrors{$k};
        }
        $i++;
    }
    mlog(0,"AUTHErrors: recalculated $i IP counters") if  $MaintenanceLog && $MaxAUTHErrors && $i;
}
