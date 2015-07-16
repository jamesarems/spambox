#line 1 "sub main::WaitForAllThreads"
package main; sub WaitForAllThreads {
    my $allstart = 0;
    my $count = time;
    while (! $allstart && time - $count < 60) {   # wait for the threads to start but max 60 seconds
        &ThreadMonitorMainLoop('MainThread waiting for threads are started');
        if ($ComWorker{10000}->{isstarted} == 1 or $ComWorker{10000}->{inerror}) {
            $allstart = 1;
        } else {
            $allstart = 0;
            Time::HiRes::sleep(0.2);
            next;
        }
        &mlogWrite();
        if ($ComWorker{10001}->{isstarted} == 1 or $ComWorker{10000}->{inerror}) {
            $allstart = 1;
        } else {
            $allstart = 0;
            Time::HiRes::sleep(0.2);
            next;
        }
        &mlogWrite();
        foreach (keys %Threads) {
            next if ($_ > 9999);  # only for ComWorkers
            &mlogWrite();
            if ($ComWorker{$_}->{issleep} == 1 or $ComWorker{$_}->{inerror}) {
                $allstart = 1;
            } else {
                $allstart = 0;
                Time::HiRes::sleep(0.2);
                last;
            }
            &mlogWrite();
        }
    }
    mlog (0,"all Threads are started");
    &ThreadMonitorMainLoop('MainThread: all threads are started');
}
