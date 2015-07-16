#line 1 "sub main::cleanTrapPB"
package main; sub cleanTrapPB {
    d('cleanTrapPB');
    my $addresses_before= my $addresses_deleted=0;
    my $t=time;
    my $maxtime = $PBTrapInterval*3600*24;
    while (my ($k,$v)=each(%PBTrap)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $addresses_before % 100;
        my ($ct,$ut,$count)=split(/\s+/o,$v);
        $addresses_before++;

        if ($t-$ct>=$maxtime && $count < $PenaltyMakeTraps) {
            delete $PBTrap{$k};
            $addresses_deleted++;
        }
    }
    mlog(0,"PBTrap: cleaning finished: before=$addresses_before, deleted=$addresses_deleted") if  $MaintenanceLog && $addresses_before != 0;
    if ($addresses_before==0) {
        %PBTrap=();
        if ($pbdb =~ /DB:/o && ! $failedTable{PBTrap}) {
        } else {
            &SaveHash('PBTrap');
        }
    }
}
