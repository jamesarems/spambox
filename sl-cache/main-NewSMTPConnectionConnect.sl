#line 1 "sub main::NewSMTPConnectionConnect"
package main; sub NewSMTPConnectionConnect {
    my $fhh=shift;
    my $fnoC;
    my $fnoS;
    my $timeout;
    my $isSSL = "$fhh" =~ /SSL/io;
    my $client;
    my $mlog = $inSIG ? \&mlog_S : \&mlog ;
    my $d = $inSIG ? \&d_S : \&d ;
    delete $SocketCalls{$fhh};
    $d->('NewSMTPConnectionConnect');
    eval{$timeout = $fhh->timeout();};
    my $tout = $isSSL ? $SSLtimeout : 2;
    eval{$fhh->timeout($tout) if (! $timeout || $timeout < $tout);};
    my $retry = 0;

    if ($isSSL) {
        ${*$fhh}{_SSL_arguments}{SSL_startHandshake} ||= 1;
        eval{$fhh->blocking(1);};
        $retry = 3;
        $client = $fhh->accept;
    } else {
        # some OS may return on non-blocking ->accept immediately but setting EAGAIN or EWOULDBLOCK
        # $client is retured but $client->connected is set to undef in case
        my $st = Time::HiRes::time();
        while ((! $client || ! $client->connected) && (Time::HiRes::time() - $st) < $tout) {
            $client = $fhh->accept;
        }
    }
    
    if(! $client || ! $client->connected) {
        while ((! $client || ! $client->connected) && $isSSL && $retry-- && ($IO::Socket::SSL::SSL_ERROR == eval('SSL_WANT_READ') ? 1 : $IO::Socket::SSL::SSL_ERROR == eval('SSL_WANT_WRITE') ) && $SSLRetryOnError) {
            &ThreadYield();
            Time::HiRes::sleep(0.5);
            $ThreadIdleTime{$WorkerNumber} += 0.5;
            $mlog->(0,"info: retry ($retry) SSL negotiation - peer socket was not ready - ".IO::Socket::SSL::errstr()) if $ConnectionLog;
            $client = $fhh->accept;
        }
        if (! $client || $client->connected) {
            my $error = $isSSL ? IO::Socket::SSL::errstr() : $!;
            eval{$timeout = $fhh->timeout();};
            $mlog->(0,"error: $WorkerName accept to client failed $fhh (timeout: $timeout s) : $error");
            $d->("accept failed: $fhh : $error") unless $inSIG;
            threadConDone($fhh);
            $! = '';
            close($fhh);
            eval{$client->close;} if $client;
            $mlog->(0,"error: $WorkerName close failed on $fhh : $!") if ($!);
            threads->yield;
            $trqueue->enqueue("failed");  # tell the main thread that we are not connected!
            threads->yield;
            $mlog->(0,"info: $WorkerName freed Main_Thread (no accept)") if($WorkerLog >= 2);
            $d->('NewSMTPConnectionConnect - no accept');
            exists $Con{$fhh} && delete $Con{$fhh};
            return;
        }
    }
    threadConDone($fhh);
    close($fhh);
    exists $Con{$fhh} && delete $Con{$fhh};
    if (exists $Con{$client}) {
        $mlog->(0,"error: internal Perl error in $WorkerName, area for $client still exists");
        threadConDone($client);
        eval{close($client)};
        threads->yield;
        $trqueue->enqueue("failed");  # tell the main thread that we are not connected!
        threads->yield;
        return;
    }
    threads->yield;
    $trqueue->enqueue("ok");       # tell the main thread that we are connected!
    threads->yield;
    $fnoC = fileno($client);
    $mlog->(0,"info: $WorkerName freed Main_Thread - $fnoC") if($WorkerLog >= 2);
    $SocketCalls{$client} = \&NewSMTPConnection;
    $SocketCallsNewCon{$client} = \&NewSMTPConnection;
    $Con{$client} = {};
    $Con{$client}->{timelast} = $Con{$client}->{timestart} = time;
    $Con{$client}->{socketcalls} = 0;
    $Con{$client}->{type} = 'C';
    $Con{$client}->{self} = $client;
    $Con{$client}->{fno} = $fnoC;
    $Con{$client}->{peerhost} = $client->peerhost();
    $Con{$client}->{peerport} = $client->peerport();
    $client->blocking(0);
    my $n = scalar keys %SocketCalls;
    $ComWorker{$WorkerNumber}->{numActCon} = int(($n+1)/2);      # set the number of active connection in thread
    threads->yield;
}
