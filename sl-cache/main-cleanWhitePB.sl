#line 1 "sub main::cleanWhitePB"
package main; sub cleanWhitePB {
    d('cleanWhitePB');
    my $ips_before= my $ips_deleted=0;
    my $t=time;
    delete $PBWhite{'0.0.0.0'};
    delete $PBWhite{''};
    my $maxtime1 = $globalWhiteExpiration*24*3600;
    my $maxtime2 = $WhiteExpiration*24*3600;

    while (my ($k,$v)=each(%PBWhite)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $ips_before % 100;
        my($ct,$ut,$pbstatus,$reason)=split(/\s+/o,$v);
        $ips_before++;

        if ($pbstatus == 3) {           # an entry from global PB
            if ($t-$ut>=$maxtime1) {
                delete $PBWhite{$k};
                $ips_deleted++;
            }
            next;
        }
        if (matchIP($k,'denySMTPConnectionsFromAlways',0,1) or (($DoDropList == 2 or $DoDropList == 3) and matchIP($k,'droplist',0,1))) {
            delete $PBWhite{$k};
            $ips_deleted++;
            next;}
        if (matchIP($k,'noPBwhite',0,1)) {
            delete $PBWhite{$k};
            $ips_deleted++;
            next;}
        if ($t-$ut>=$maxtime2) {
            delete $PBWhite{$k};
            $ips_deleted++;
        }
    }
    mlog(0,"PenaltyBox: cleaning WhiteBox (PBWhite) finished: IP\'s before=$ips_before, deleted=$ips_deleted") if $MaintenanceLog && $ips_before != 0;
    if ( $ips_before == 0) {
        %PBWhite = ();
        if ($pbdb =~ /DB:/o && ! $failedTable{PBWhite}) {
        } else {
            &SaveHash('PBWhite');
        }
    }
}
