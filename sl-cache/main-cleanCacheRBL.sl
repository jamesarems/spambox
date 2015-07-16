#line 1 "sub main::cleanCacheRBL"
package main; sub cleanCacheRBL {
    d('cleanCacheRBL');
    my $ips_before = my $ips_deleted = 0;
    my $t = time;
    my $ct;
    my $mm;
    my $status;
    my @sp;
    my $maxtime = $RBLCacheExp * 3600;
    while (my ($k,$v)=each(%RBLCache)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $ips_deleted % 100;
        ( $ct, $mm, $status, @sp ) = split( ' ', $v );

        $ips_before++;
        if ( $t - $ct >= $maxtime  ) {
            delete $RBLCache{$k};
            $ips_deleted++;
            next;
        }
        next if $status == 2;
        my $spstr = join(' ',@sp);
        foreach my $sp (@sp) {
            my $tsp = $sp;
            $tsp =~ s/([^\{]+).*/$1/o;
            next if grep(/\Q$tsp\E/i,@rbllist);
            $spstr =~ s/ ?\Q$sp\E//ig;
        }
        if ($spstr) {
            $RBLCache{$k} = "$ct $mm $status $spstr";
        } else {
            delete $RBLCache{$k};
            $ips_deleted++;
        }
    }
    mlog( 0, "DNSBLCache: cleaning cache finished: IP\'s before=$ips_before, deleted=$ips_deleted" ) if $MaintenanceLog && $ips_before != 0;
    if ( $ips_before == 0) {
        %RBLCache=();
        if ($pbdb =~ /DB:/o && ! $failedTable{RBLCache}) {
        } else {
            &SaveHash('RBLCache');
        }
    }
}
