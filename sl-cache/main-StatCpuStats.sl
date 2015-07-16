#line 1 "sub main::StatCpuStats"
package main; sub StatCpuStats {
    my $upt = time - $Stats{starttime};
    $Stats{cpuTime} = $upt * ($NumComWorkers + 3);
    my $widle = &workerIdleTime();
    $widle = min($widle,$Stats{cpuTime});
    $Stats{cpuBusyTime} = ($Stats{cpuTime} - $widle) || 1;
}
