#line 1 "sub main::ThreadGetNewCon"
package main; sub ThreadGetNewCon {
    my $TGNCth;
    my $TGNCfno;
    my $TGNCsockType;
    my $TGNCfhInfo;
    my $TGNCfh;
    my $TGNCn = scalar(keys %SocketCalls);
    d('ThreadGetNewCon') unless $inSIG;
    $ComWorker{$WorkerNumber}->{numActCon} = int(($TGNCn+1)/2);      # set the number of active connection in thread
    $TGNCth = $ComWorker{$WorkerNumber}->{newCon}->{th};
    threads->yield;
    return if (! $TGNCth);
    ($TGNCfno,$TGNCsockType,$TGNCfhInfo) = split(/,/,$ComWorker{$WorkerNumber}->{newCon}->{fno});
    $TGNCfh = &getfh4fileno($TGNCfno,$TGNCsockType,$TGNCfhInfo);            # get fh from fileno
    if (! $TGNCfh) {
        $ComWorker{$WorkerNumber}->{newCon}->{fno} = '';      # make the thread ready to get new connection
        $ComWorker{$WorkerNumber}->{newCon}->{th} = '';
        threads->yield;
        $trqueue->enqueue("failed");  # tell the main thread that we are not connected!
        threads->yield;
        return;
    }
    my $TGNCnfno = fileno($TGNCfh);
    $SocketCalls{$TGNCfh} = $tThreadHandler{$TGNCth};    # set sub for Handler
    mlog(0,"info: $WorkerName got connection from MainThread") if ($WorkerLog == 1 && !$inSIG);
    mlog(0,"info: $WorkerName got connection from MainThread - $TGNCfno/$TGNCnfno") if ($WorkerLog >= 2 && ! $inSIG);
    $SocketCalls{$TGNCfh}->($TGNCfh);                 # do the first SocketCall to get connected
                                              # and free up MainLoop from wait
    $ThreadDebug = 0;
    $TGNCn = scalar(keys %SocketCalls);
    $ComWorker{$WorkerNumber}->{numActCon} = int(($TGNCn+1)/2);      # set the number of active connection in thread
    threads->yield;
    $ComWorker{$WorkerNumber}->{newCon}->{fno} = '';      # make the thread ready to get new connection
    threads->yield;
    $ComWorker{$WorkerNumber}->{newCon}->{th} = '';
    threads->yield;
}
