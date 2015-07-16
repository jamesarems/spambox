#line 1 "sub main::cleanCacheBATVTag"
package main; sub cleanCacheBATVTag {
    d('cleanCacheBATVTag');
    my $ips_before= my $ips_deleted=0;
    my $ct;
    my $today = (time / 86400) % 1000;
    while (my ($k,$v)=each(%BATVTag)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $ips_before % 100;
        $ips_before++;

        if (my ($gen, $day, $hash, $orig_user) = ($v =~ /^prvs=(\d)(\d\d\d)(\w{6})=(.*)/o) ) {
            my $dt = ($day - $today + 1000) % 1000;
            if ($dt > 7) {
                delete $BATVTag{$k};
                $ips_deleted++;
            }
        }
    }
    mlog(0,"BATVTag: cleaning cache finished: BATVTag\'s before=$ips_before, deleted=$ips_deleted") if  $MaintenanceLog && $ips_before != 0;
    if ($ips_before==0) {
        %BATVTag=();
        if ($pbdb =~ /DB:/o && ! $failedTable{BATVTag}) {
        } else {
            &SaveHash('BATVTag');
        }
    }
}
