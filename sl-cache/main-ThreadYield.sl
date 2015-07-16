#line 1 "sub main::ThreadYield"
package main; sub ThreadYield {
    threads->yield();
    my $CycleTime;
    if ($WorkerNumber == 10000) {
        $CycleTime = $MaintThreadCycleTime;
    } elsif ($WorkerNumber == 10001) {
        $CycleTime = $RebuildThreadCycleTime;
    } elsif ( $EnableHighPerformance ) {
        $CycleTime = min($ThreadCycleTime,$EnableHighPerformance);
    } else {
        $CycleTime = $ThreadCycleTime;
    }
    return if (! $CycleTime);
    my $t = $CycleTime / 1000000;
    Time::HiRes::sleep($t);
    $ThreadIdleTime{$WorkerNumber} += $t;
}
