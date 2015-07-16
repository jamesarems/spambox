#line 1 "sub main::sigCentralSet"
package main; sub sigCentralSet {
    my $sig;
    sigCentralHandler(0);
    sigToMainThread(0);
    sigTermWorker(0);
    foreach (keys %SIG) {
       next if ($_ eq '__DIE__');
       next if ($_ eq '__WARN__');
       next if ($_ eq 'INT');
       next if ($_ eq 'TERM');
       next if ($_ eq 'HUP');
       next if ($_ eq 'CHLD');
       next if ($_ eq 'CLD');
       next if ($_ eq 'USR1');
       next if ($_ eq 'USR2');
       next if ($_ eq 'ALRM');
       $SIG{$_} = \&sigCentralHandler;
       $sig .= " - $_($signo{$_})";
    }
    if (exists $SIG{USR1}) {$SIG{USR1} = \&sigToMainThread ;$sig .= " - USR1($signo{USR1})";}
    if (exists $SIG{USR2}) {$SIG{USR2} = \&sigToMainThread ;$sig .= " - USR2($signo{USR2})";}
    $SIG{ALRM} = \&sigCentralHandler;
    alarm 0;
    $SIG{PIPE} = "IGNORE";
    $SIG{INT}  = ($WorkerNumber == 0) ? 'IGNORE' : \&sigToMainThread;
    $SIG{'__WARN__'} = sub { warn $_[0] if (!($AsADaemon || $AsAService) && $_[0] !~ /uninitialized/oi)};
    $SIG{TERM}  = ($WorkerNumber == 0) ? 'IGNORE' : \&sigTermWorker;
    $SIG{HUP}  = ($WorkerNumber == 0) ? 'IGNORE' : \&sigToMainThread;
    $sig .= " - INT($signo{INT}) - HUP($signo{HUP}) - TERM($signo{TERM}) - CHLD($signo{CHLD}) - CLD($signo{CLD}) - ALRM($signo{ALRM})";
    mlog(0,"info: central signalhandler$sig - installed") if ($SignalLog && $WorkerNumber == 0);
}
