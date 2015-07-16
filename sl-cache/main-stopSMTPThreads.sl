#line 1 "sub main::stopSMTPThreads"
package main; sub stopSMTPThreads {
    foreach (keys %Threads) {
        next if $_ > 9999;
        tellThreadQuit($_) unless $ComWorker{$_}->{finished};
    }
    mlog (0,"waiting for all SMTP-Workers to be finished");
    &mlogWrite();
    my $allend = 0;
    my $count = time;
    my $timeout = $MaxFinConWaitTime + 5;
    while (! $allend && time - $count < $timeout) {   # wait for the threads to end but max 50 seconds
        foreach (keys %Threads) {
            next if $_ > 9999;
            &MainLoop2();
            &ThreadMonitorMainLoop('MainThread waiting until end of all SMTP-threads');
            &mlogWrite();
            if ($ComWorker{$_}->{finished} == 1) {
                $allend = 1;
            } else {
                $allend = 0;
                Time::HiRes::sleep(0.2);
                last;
            }
        }
    }
    mlog (0,"SMTP Workers finished") if $allend;
    mlog (0,"error: at least one of the SMTP workers has not finished work within $timeout seconds") if ! $allend;
    &mlogWrite();
    return $allend;
}
