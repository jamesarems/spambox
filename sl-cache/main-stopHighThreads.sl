#line 1 "sub main::stopHighThreads"
package main; sub stopHighThreads {
    foreach (10000, 10001) {
        tellThreadQuit($_) unless $ComWorker{$_}->{finished};
    }
    mlog (0,"waiting for high Workers to be finished");
    &mlogWrite();
    my $allend = 0;
    my $count = time;
    while (! $allend && time - $count < 50) {   # wait for the threads to end but max 50 seconds
        foreach (10000, 10001) {
            &MainLoop2();
            &ThreadMonitorMainLoop('MainThread waiting until end of high threads');
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
    mlog (0,"high workers finished work") if $allend;
    mlog (0,"error: at least one of the high workers has not finished work within 50 seconds") if ! $allend;
    &mlogWrite();
    return $allend;
}
