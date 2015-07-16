#line 1 "sub main::ThreadWaitFinCon"
package main; sub ThreadWaitFinCon {
    $ThreadsDoStatus = 1;
    while (1) {
        my $notallfinished = 10;
        my $maxtime = $smtpIdleTimeout > 0 ? $smtpIdleTimeout + 30 : 210;
        my $starttime = time;
        mlog(0,"info: $WorkerName is waiting until Workers finished current SMTP-connections or $maxtime seconds - to renew Socket-Listener");
        while ($notallfinished > 1 && time - $starttime < $maxtime) {
            $nextConSync = time - 1;
            &ConDone();
            my ($w,$t) = &getStuckWorker();
            $lastThreadsDoStatus = time;
            $ThreadsDoStatus = 1;
            Time::HiRes::sleep(0.5);
            $ThreadIdleTime{$WorkerNumber} += 0.5;
            &MainLoop2();
            &serviceCheck();
            threads->yield;
            $notallfinished = scalar(keys %ConFno) + $smtpConcurrentSessions + $SMTPSessionIP{Total};
            &ThreadMonitorMainLoop("wait finished workers - for renew listener");
            mlogWrite();
        }
        if ($notallfinished < 2) {  # there are no more active connections
            mlog(0,"info: $WorkerName detected  - all Workers are finished current SMTP-connections");
            $ThreadsDoStatus = 0;
            return;
        } else {                  # some connection are active - try to restart
            $notallfinished = scalar(keys %ConFno);
            &downSPAMBOX("try restarting SPAMBOX: con in thread: $notallfinished, con concurrent: $smtpConcurrentSessions, con total: $SMTPSessionIP{Total}");
            _assp_try_restart;
        }
    }
}
