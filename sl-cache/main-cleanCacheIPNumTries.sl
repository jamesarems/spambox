#line 1 "sub main::cleanCacheIPNumTries"
package main; sub cleanCacheIPNumTries {
    d('cleanCacheIPNumTries');
    my $ips_before= my $ips_deleted=0;
    my $ct;
    my $t=time;
    while (my ($k,$v)=each(%IPNumTries)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $ips_before % 100;
        $ips_before++;

        if ((($t - $IPNumTriesExpiration{$k}) > $maxSMTPipExpiration)  ||
            (($t - $IPNumTriesDuration{$k}) > $maxSMTPipDuration) &&
             ($IPNumTries{$k} < $maxSMTPipConnects))
        {
            $ips_deleted++;
            delete $IPNumTries{$k};
            delete $IPNumTriesDuration{$k};
            delete $IPNumTriesExpiration{$k};
        }
    }
    mlog(0,"IPNumTries: cleaning cache finished: IP\'s before=$ips_before, deleted=$ips_deleted") if  $MaintenanceLog && $ips_before > 0;
}
