#line 1 "sub main::workerIdleTime"
package main; sub workerIdleTime {
    my $idleTime = 0;
    my $stime = time - $Stats{starttime};
    eval{
        for (0,1...$NumComWorkers,10000,10001) {
            my $offset = 0;
            $offset = time - $WorkerLastAct{$_} if ($_ > 0 && $_ < 10000 && $ComWorker{$_}->{issleep});
            $idleTime += min(int($ThreadIdleTime{$_}+0.5) + $offset,$stime);
        }
    };
    return $idleTime;
}
