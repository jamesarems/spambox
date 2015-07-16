#line 1 "sub main::ConToThread"
package main; sub ConToThread {
    my $fh = shift;
    my $starttime=Time::HiRes::time();
    &ThreadMonitorMainLoop('MainLoop start connection transfer');
    my $fno = fileno($fh);
    my $exceptCount = 0;
    my ($worker,$numcon,$loop,$except,$retval,$time);
    $Fileno{$fno} = $fh;   # store fileno and fh
    mlog(0,"info: $WorkerName looks up the best Worker for new connection - $fno") if ($WorkerLog >= 2);

    do {
        $except = 0;
        do {
            $loop = 0;
            ($worker,$numcon) = &getBestWorker($fh);      # get the best worker for this connection
            my ($w,$t) = &getStuckWorker();
            if ($worker == -1) {
                &ThreadMonitorMainLoop('MainLoop is unable to transfer connection');
                mlog(0,"warning: $WorkerName is unable to transfer connection to any worker - try again!");
                &mlogWrite();
                $exceptCount++;
                my $wt = $ConnectionTransferTimeOut * $exceptCount;
                if ($exceptCount > 3) {
                    mlog(0,"error: $WorkerName is unable to transfer connection to any worker within $wt seconds - restart SPAMBOX!");
                    &downSPAMBOX("restarting");
                    _spambox_try_restart;
                }
                $loop = 1;
            } else {
                threads->yield;
                $willSIG = 0;                # tell all workers - there is no need to wait
                threads->yield;
            }
        } while $loop;
        &ThreadMonitorMainLoop("MainLoop get the best worker = $worker ($numcon sockets)");
        my $rq = 'r'.$worker;
        eval {
            while ($ThreadQueue{$rq}->dequeue_nb()) {threads->yield;}
            while ($ThreadQueue{$worker}->dequeue_nb()) {threads->yield;}
        };
        my ($sockType,$ht) = split(/=/o,"$fh");
        my $fhInfo = $fh->sockhost() . ':' . $fh->sockport();
        $ComWorker{$worker}->{newCon}->{fno} = "$fno,$sockType,$fhInfo";
        threads->yield;
        $ComWorker{$worker}->{newCon}->{th} = $ThreadHandler{$fh};  # tell Thread what to do
        threads->yield;
        $ThreadQueue{$worker}->enqueue('run');
        &ThreadYield();
        if ($numcon == 0){
           &ThreadMonitorMainLoop("MainLoop waiting for idle worker = $worker ($numcon sockets)");
        } else {
           &ThreadMonitorMainLoop("MainLoop waiting for interrupted worker = $worker ($numcon sockets)");
        }
        mlog(0,"info: $WorkerName will wait (max $ConnectionTransferTimeOut s) for the answer of Worker_$worker which handles $numcon sockets") if ($WorkerLog >= 2);
        my $wtime = $time = Time::HiRes::time();
        $nextLoop2 = $time + 0.3;
        threads->yield();
        $retval = $ThreadQueue{$rq}->dequeue_nb();
        threads->yield();
        while (! $retval){
           &ThreadYield();
           ($retval = $ThreadQueue{$rq}->dequeue_nb()) and last;    # come out here as fast as possible
           &ThreadYield();
           &MainLoop2();                                   # make sure webtraffic is going on
           if ($worker > $NumComWorkers) {                 # NumComWorkers could be changed in MainLoop2
               eval {
                   while ($ThreadQueue{$rq}->dequeue_nb()) {threads->yield;}
                   while ($ThreadQueue{$worker}->dequeue_nb()) {threads->yield;}
               };
               mlog(0,"info: Worker_$worker was killed - will try other worker") if ($WorkerLog >= 2);
               &mlogWrite();
               $except = 1;
               last;
           }
           ($retval = $ThreadQueue{$rq}->dequeue_nb()) and last;    # come out here as fast as possible
           &ThreadYield();
#           ($retval = $ThreadQueue{$rq}->dequeue_nb()) and last;    # come out here as fast as possible
           if (time - $wtime > $ConnectionTransferTimeOut) {
               mlog(0,"info: Worker_$worker handles $numcon sockets and does not answer - will try other worker") if ($WorkerLog >= 2);
               $ComWorker{$worker}->{inerror} = 1;
               $ComWorker{$worker}->{newCon}->{fno} = '';
               $ComWorker{$worker}->{newCon}->{th} = '';  # tell Thread forget what to do
               eval {
                   while ($ThreadQueue{$rq}->dequeue_nb()) {threads->yield;}
                   while ($ThreadQueue{$worker}->dequeue_nb()) {threads->yield;}
               };
               &mlogWrite();
               $except = 1;
               last;
           }
        }
    } while $except;

    my $transtime = sprintf("%.3f",Time::HiRes::time() - $starttime);
    if ($numcon == 0){
       &ThreadMonitorMainLoop("MainLoop freed by idle worker = $worker");
       mlog(0,"info: $WorkerName freed by idle Worker_$worker in $transtime seconds - got ($retval)") if ($WorkerLog);
       $TransferNoInterruptTime += $transtime;
       threads->yield;
    } else {
       &ThreadMonitorMainLoop("MainLoop freed by interrupted worker = $worker");
       mlog(0,"info: $WorkerName freed by interrupted Worker_$worker in $transtime seconds - got ($retval)") if ($WorkerLog);
       $TransferInterrupt++;
       threads->yield;
       $TransferInterruptTime += $transtime;
       threads->yield;
       $i_bw_time += sprintf("%.3f",$time - $starttime);
       threads->yield;
       $i_tw_time += sprintf("%.3f",Time::HiRes::time() - $time);
       threads->yield;
    }
    $TransferTime += $transtime;
    threads->yield;
    $TransferCount++;
    threads->yield;
    if ($retval eq 'ok') {
       delete $failedFH{$fh};
       my $nfno = fileno($fh);
       if($fno ne $nfno) {
          mlog(0,"$fh has changed fd from $fno to $nfno");
          delete $Fileno{$fno};
          $Fileno{$nfno} = $fh;
          unpoll($fh,$readable);
          &dopoll($fh,$readable,POLLIN);
       }
       return;
    } else {
       $failedFH{$fh} = 0 if (! exists $failedFH{$fh});
       $failedFH{$fh}++;
    }
    if ($failedFH{$fh} > 10) {
        &mlogWrite();
        &resetFH($fh);
        $errorFH = 1;
        &mlogWrite();
    }
}
