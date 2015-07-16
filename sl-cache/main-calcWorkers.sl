#line 1 "sub main::calcWorkers"
package main; sub calcWorkers {
    my $runtime = int((time - $PerfStartTime)/60);
    my $tc = $TransferCount;
    my $ti = $TransferInterrupt;
    return $NumComWorkers if $runtime * $NumComWorkers == 0;
    return $NumComWorkers if $ti == 0;   # no interrupts
    return $NumComWorkers if $tc < 100;  # we need at least 100 connections to calculate
    if ($tc/($runtime * $NumComWorkers) < 5) {  # less than 5 connection per thread per minute
        return $NumComWorkers if $NumComWorkers <= 5;
        return 5;
    }

    my $w = 11 - $tc/$ti;
    return $NumComWorkers if $w < 2;
    $w = 1 + $w/10;
    $w = int($NumComWorkers * $w) + 1;
    return $w if($w <= 15 + $ReservedOutboundWorkers);
    return 15 + $ReservedOutboundWorkers;
}
