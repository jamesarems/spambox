#line 1 "sub main::getBestWorker"
package main; sub getBestWorker {
    my $fh = shift;
    my $worker = 0;
    my $numcon;
    my %Workers = ();
    my $trytime = time;
    my $error_was_logged = 0;
    while ($worker == 0) {          # first get all numbers of connections or 0
        &MainLoop2();               # keep the GUI running
        $numcon = 999999;
        %Workers = ();
        &ThreadMonitorMainLoop('MainThread entry getBestWorker');
        if ($ReservedOutboundWorkers && $ReservedOutboundWorkers < $NumComWorkers && &matchFH($fh, @lsnRelayI)) {    # Relay listener reservation
            for (my $i = $NumComWorkers; $i > 0; $i--) {
                next if($ComWorker{$i}->{inerror} || ! $ComWorker{$i}->{run});
                return $i,0 if $ComWorker{$i}->{issleep};    # a thread with nothing to do
                $numcon = $ComWorker{$i}->{numActCon};
                $worker = $i;
                $Workers{$i} = $numcon;
                threads->yield;
            }
        } else {     # inbound Emails or outbound without defined ReservedOutboundWorkers
            for (my $i = 1; $i<=$NumComWorkers-$ReservedOutboundWorkers; $i++) {
                next if($ComWorker{$i}->{inerror} || ! $ComWorker{$i}->{run});
                return $i,0 if $ComWorker{$i}->{issleep};    # a thread with nothing to do
                $numcon = $ComWorker{$i}->{numActCon};
                $worker = $i;
                $Workers{$i} = $numcon;
                threads->yield;
            }
        }
        &ThreadMonitorMainLoop('MainThread list possible workers');
        if( $worker == 0) {           # there was no accessible worker
            mlog(0,"info: unable to detect any running worker for a new connection - wait (max $ConnectionTransferTimeOut seconds)") unless $error_was_logged & 1;
            $error_was_logged &= 1;
            &MainLoop2();             # keep the GUI running
            if (time - $trytime > $ConnectionTransferTimeOut) {   # the connection transfer timeout is reached
                &ThreadYield();
                $willSIG = 0;
                &ThreadYield();
                mlog(0,"info: ConnectionTransferTimeOut ($ConnectionTransferTimeOut seconds) is now reached");
                return -1,0;
            }
            Time::HiRes::sleep(0.01) ;   # there is no worker able to take the connection - so wait
            next;
        }
        &ThreadMonitorMainLoop('MainThread check transfer timeout (1)');
        $worker = 0;    # we have to interrupt workers - check if it is possible
        &MainLoop2();   # keep the GUI running
        threads->yield;
        $willSIG = 1 if ($willSIG == 0);  # tell the workers that we have to interrupt
        threads->yield;
        my @tmpSortedKeys =  sort { $Workers{$main::a} <=> $Workers{$main::b}} keys(%Workers);  # sort the workers by there active connection
        &ThreadMonitorMainLoop('MainThread sort best workers');
        while (@tmpSortedKeys) {
            my $key = shift @tmpSortedKeys;
            if ($ComWorker{$key}->{issleep}) {
                threads->yield;
                $willSIG = 0;   # tell all workers - there is no need to wait
                threads->yield;
                return $key,0;  # return - the worker is now free
            }
            threads->yield;
            $key = $willSIG - 11000 if ($willSIG > 11000);  # is there a worker waiting for an interrupt than we'll use it
            threads->yield;
            $worker = $key;
            $numcon = $Workers{$key};
            mlog(0,"info: try to interrupt worker Worker_$key ($numcon) for new connection") if ($WorkerLog >= 2);
            &ThreadMonitorMainLoop("willSIG = $willSIG - try to interrupt worker Worker_$key ($numcon) for new connection");
            if ($ComWorker{$key}->{CANSIG}) {       # yes we can interrupt this worker
                $Threads{$key}->kill('CONT');
                mlog(0,"info: $WorkerName interrupted Worker_$key ($numcon) to submit the connection") if ($WorkerLog >= 2);
                &ThreadMonitorMainLoop("willSIG = $willSIG - $WorkerName interrupted Worker_$key ($numcon) to submit the connection");
                threads->yield;
                $willSIG = 0;   # tell all workers - there is no need to wait
                threads->yield;
                return $key,$numcon;
            }
            &MainLoop2();    # keep the GUI running
            &ThreadYield();
        }
        mlog(0,"info: $WorkerName is unable to interrupt any worker for new connection - wait (max $ConnectionTransferTimeOut seconds)") if ($WorkerLog >= 2 && $error_was_logged & 2);
        $error_was_logged &= 2;
        $worker = 0;
        &MainLoop2();        # keep the GUI running
        if (time - $trytime > $ConnectionTransferTimeOut) {    # the connection transfer timeout is reached
            &ThreadYield();
            $willSIG = 0;        # tell all workers - there is no need to wait
            &ThreadYield();
            return -1,0;
        }
        &ThreadMonitorMainLoop('MainThread check transfer timeout (2)');
        Time::HiRes::sleep(0.01) ;   # there is no worker able to take the connection - so wait
        &ThreadYield();
    }
    &ThreadYield();
    return $worker,$numcon;
}
