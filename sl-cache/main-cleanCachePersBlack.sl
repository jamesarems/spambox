#line 1 "sub main::cleanCachePersBlack"
package main; sub cleanCachePersBlack {
    d('cleanCachePersBlack');
    &ThreadMaintMain2() if $WorkerNumber == 10000;
    my $adr_before= my $adr_deleted=0;
    my $ct;
    my $t=time;
    my $maxtime = $MaxWhitelistDays*3600*24;
    if ($MaxWhitelistDays) {
        while (my ($k,$v)=each(%PersBlack)) {
            &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $adr_before % 100;
            $adr_before++;

            if ($t-$v>=$maxtime || $k =~ /,$skipAddrListRE$/o) {
                delete $PersBlack{$k};
                $adr_deleted++;
            }
        }
        mlog(0,"PersBlackCache: cleaning cache finished: entries before=$adr_before, deleted=$adr_deleted") if  $MaintenanceLog && $adr_before != 0;
        if ($adr_before==0 or $adr_before == $adr_deleted) {
            %PersBlack=();
            $PersBlackHasRecords = 0;
            if ($pbdb =~ /DB:/o && ! $failedTable{PersBlack}) {
            } else {
                &SaveHash('PersBlack');
            }
        } else {
            $PersBlackHasRecords = 1;
        }
    }
}
