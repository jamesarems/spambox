#line 1 "sub main::processMaintCMDQueue"
package main; sub processMaintCMDQueue {
    my $Iam = $WorkerNumber;
    return 0 if $Iam < 10000;
    my $wasrun = 0;
    my $l = $lastd{$Iam};
    &checkDBCon() if $Iam == 10001;
    my @requeue;
    
    while ($cmdQueueReleased && (my $pending = $cmdQueue->pending())) {
        $WorkerLastAct{$Iam} = time if $Iam == 10001;
        my ($requworker,$sub,$parmnum,$parm);
        d("get CMD from cmdQueue");
        { lock(%cmdQParm) if is_shared(%cmdQParm);
        threads->yield;
        my $item = $cmdQueue->dequeue_nb(1);
        threads->yield;
        ($sub,$parmnum) = $item =~ /^sub\(([^\)]+)\)(.*)/o;
        $requworker = $1 if $sub =~ s/^(\d+)//o;
        d("run CMD ($sub) from cmdQueue - worker $requworker");
        $parm = $cmdQParm{$parmnum};
        delete $cmdQParm{$parmnum};
        $pending -= 1;
        }
        next if ($sub eq 'SPFbg' && (! $ComWorker{$Iam}->{run} || $doShutdownForce || $doShutdown));
        if ($sub) {
            if ($requworker && $requworker != $Iam) {
                push(@requeue, "$requworker$sub", $parm);
                d("requeued CMD ($sub) to - worker $requworker");
                next;
            }
            mlog(0,"info: got command '$sub' from command queue - $pending commands pending") if $MaintenanceLog >= 2;
            $wasrun = 1;
            eval{&$sub($parm);};
            if ($@) {
                mlog(0,"error: cmdqueue failed '$sub' - $@");
            }
            &ThreadYield();
        }
    }
    while (@requeue) {
        &cmdToThread( shift(@requeue), shift(@requeue) );
        $wasrun = 1;
    }
    $lastd{$Iam} = $l;
    return $wasrun;
}
