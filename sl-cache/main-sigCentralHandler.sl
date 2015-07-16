#line 1 "sub main::sigCentralHandler"
package main; sub sigCentralHandler {
    my $sig = shift;
    return unless $sig;
    local $_ = undef;
    local @_ = ();
    local $/ = undef;
    my ($package, $file, $line) = caller;
    if (! $SignalLog) {
        $sigCount{$sig}++;
        if (time > $nextSigCountCheck) {
            $nextSigCountCheck = time + 600;
            for (keys %sigCount) {
                mlog(0,"warning: got unexpected signal $_ $sigCount{$_} times in last 10 minutes!");
            }
            %sigCount = ();
        }
    } else {
        %sigCount = ();
    }
    mlog(0,"warning: got unexpected signal $sig in $WorkerName: package - $package, file - $file, line - $line!") if ($SignalLog);
    if ($SignalLog > 1) {
        my $m = &timestring();
        $m .= " warning: got unexpected signal $sig in $WorkerName: package - $package, file - $file, line - $line!";
        my $S;
        open $S, '>>',"$base/debugSignal.txt";
        binmode $S;
        print $S "$m\n";
        close $S;
    }
    if ($sig =~ /abrt|break|quit|kill|term|int/io) {
      if ($WorkerNumber == 0) {
        &downSPAMBOX("restarting on signal $sig");
        _assp_try_restart;
      } else {
        $doShutdown = time + 15;
        threads->yield();
        $ComWorker{$WorkerNumber}->{run} = 0 ;
        $ComWorker{$WorkerNumber}->{inerror} = 1 ;
        threads->yield();
        die "error: got unexpected signal $sig in $WorkerName: package - $package, file - $file, line - $line!\n";
      }
    }
    $SIG{$sig} = \&sigCentralHandler;
}
