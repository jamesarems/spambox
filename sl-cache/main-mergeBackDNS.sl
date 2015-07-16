#line 1 "sub main::mergeBackDNS"
package main; sub mergeBackDNS {
    my $file = shift;
    d('mergeBackDNS-start');
    my $hash = $useDB4IntCache && $CanUseBerkeleyDB && ($DBusedDriver ne 'BerkeleyDB' or ($DBusedDriver eq 'BerkeleyDB' && $pbdb !~ /DB:/io) ) ? 'BackDNS2' : 'BackDNS';
    my $f;
    my $count = 0;
    my $tc = 0;
    my $time = time + 3600 * 30 - $BackDNSInterval * 3600 * 24;
    (open $f,'<' ,"$file") or return 0;
    mlog(0,"info: merging BackDNSFile $file in to cache $hash") if $MaintenanceLog;
    binmode $f;
    while (my $line = (<$f>)) {
        $line =~ s/\r?\n?$//o;
        next if $line =~ /^[^\d]|127\./o;
        ${$hash}{$line} = $time . ' 1';
        $count++;
        $tc++;
        if ($tc == 100) {
            $lastd{10000} = "filling $hash - $count records added from $file";
            last if(! $ComWorker{$WorkerNumber}->{run});
            $tc = 0;
            &ThreadMaintMain2() if $WorkerNumber == 10000;
        }
    }
    close $f;
    mlog(0,"info: finished merging BackDNSFile $file with ".nN($count)." records in to cache $hash") if $MaintenanceLog;
    $FileUpdate{"$file".'localBackDNSFile'} = ftime($file);
    return if(! $ComWorker{$WorkerNumber}->{run});
    if ($hash eq 'BackDNS2') {
        &cleanCacheBackDNS2();
    } else {
        &cleanCacheBackDNS() unless ($mysqlSlaveMode && $pbdb =~ /DB:/o);
    }
    return 1;
}
