#line 1 "sub main::cleanBlackPB"
package main; sub cleanBlackPB {
    d('cleanBlackPB');
    if ($PenaltyExpiration==0) {
        %PBBlack = ();
        &SaveHash('PBBlack') unless ($pbdb =~ /DB:/o && ! $failedTable{PBBlack});
        return;
    }

    my $ips_before= my $ips_deleted=0;
    my $t=time;
    my $tdif;
    my $tdifut;
    my($ct,$ut,$pbstatus,$score,$sip,$reason);
    my $expmin=$PenaltyExpiration*60;
    delete $PBBlack{'0.0.0.0'};
    delete $PBBlack{''};
    while (my ($k,$v)=each(%PBBlack)) {
        ($ct,$ut,$pbstatus,$score,$sip,$reason)=split(/\s+/o,$v);
        $tdif=$t-$ct;
        $tdifut=$t-$ut;
        $ips_before++;

        if ($k =~ /$IPprivate/o) {
            delete $PBBlack{$k};
            $ips_deleted++;
            next;
        }

        if ($reason =~ /GLOBALPB/io) {
            if ($tdifut > $globalBlackExpiration*3600) {
                delete $PBBlack{$k};
                $ips_deleted++;
            }
            next;
        }

        if ($tdif>$PenaltyDuration*60 && $score<$PenaltyLimit ) {
            delete $PBBlack{$k};
            $ips_deleted++;
            next;}

        if ($tdif>$PenaltyExpiration*60 && $score<$PenaltyExtreme) {
            delete $PBBlack{$k};
            $ips_deleted++;
            next;}

        if (exists $PBWhite{$k} || (matchIP($k,'ispip',0,1))  || matchIP($k,'noProcessingIPs',0,1) || matchIP($k,'whiteListedIPs',0,1)  || (matchIP($k,'noDelay',0,1)) || (matchIP($k,'noPB',0,1)) || ($contentOnlyRe && $k=~/$contentOnlyReRE/)) {
            delete $PBBlack{$k};
            $ips_deleted++;
            next;}

        if ($tdif>$ExtremeExpiration*60*60*24 && $score>=$PenaltyExtreme) {
            delete $PBBlack{$k};
            $ips_deleted++;
            next;}
    }
    if ($ips_before==0) {
        %PBBlack=();
        &SaveHash('PBBlack') unless ($pbdb =~ /DB:/o)
    }
    mlog(0,"PenaltyBox: cleaning BlackBox (PBBlack) finished: IP\'s before=$ips_before, deleted=$ips_deleted") if $MaintenanceLog && $ips_before != 0;
}
