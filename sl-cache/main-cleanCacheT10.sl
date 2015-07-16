#line 1 "sub main::cleanCacheT10"
package main; sub cleanCacheT10 {
    d('cleanCacheT10');
    my $i = my $del = 0;
    my $t = time - 25 * 60 * 60;
    while (my ($k,$v)=each(%T10StatT)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $i % 100;
        if ($v < $t) {
            delete $T10StatT{$k};
            delete $T10StatD{$k};
            delete $T10StatI{$k};
            delete $T10StatR{$k};
            delete $T10StatS{$k};
            $del++;
        }
        $i++;
    }
    mlog(0,"Top-Ten-Stats: removed $del entries from $i") if $MaintenanceLog >= 2 && $i;
}
