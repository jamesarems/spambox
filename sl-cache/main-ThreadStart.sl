#line 1 "sub main::ThreadStart"
package main; sub ThreadStart {
    my $Iam = shift;
    $tqueue = shift;
    $trqueue = shift;
    $WorkerNumber = $Iam;
    threads->detach();
    close STDOUT;
    close STDERR;
    close STDIN;
    if ($CanUseBerkeleyDB) {
        eval('use BerkeleyDB;');
        if ($VerBerkeleyDB lt '0.42') {
            *{'BerkeleyDB::_tiedHash::CLEAR'} = *{'main::BDB_CLEAR'};
        }
        *{'BerkeleyDB::_tiedHash::STORE'} = *{'main::BDB_STORE'};
        *{'BerkeleyDB::_tiedHash::DELETE'} = *{'main::BDB_DELETE'};
    }
    unloadComThreadModules() if $undefMEM;
    my $exception = '';
    do {
      $exception = '';
      %dampedFH = ();
      $calledfromThread = 1;
      $WorkerName = "Worker_$Iam";
      &initGlobalThreadVar();
      eval{
          &initDBHashes();
          &initPrivatHashes();
      };
      if ($@) {
          mlog(0,"$WorkerName will now try to recover from the startup error in 5 seconds");
          sleep 5;
          $ThreadIdleTime{$WorkerNumber} += 5;
          mlog(0,"$WorkerName try to recover from the startup error");
          &clearDBCon();
          $ComWorker{$Iam}->{run} = 1;
          $ComWorker{$Iam}->{inerror} = 0;
          &initDBHashes();
          &initPrivatHashes();
          mlog(0,"$WorkerName recovered successful from the startup error");
      }
      
      mlog(0,"$WorkerName started");
      &sigCentralSet();
      &sigon(__LINE__);
      while ($ComWorker{$Iam}->{run}) {
          my $run = eval {&ThreadMain();};
          $exception = $@ if $@;
          if (! $exception && ! $run && $ComWorker{$Iam}->{run}) {
              &sigoff(__LINE__);
              &ThreadGoSleep($Iam);
              &sigon(__LINE__);
          }
      }
      if (!$exception && ! $ComWorker{$Iam}->{run}){
          foreach my $fh (keys %Con) {
              removeCrashFile($fh);
          }
          $ComWorker{$Iam}->{run} = 2;
          my $stopTime = time + $MaxFinConWaitTime;
          mlog(0,"$WorkerName has active connections. Will wait until all connections are finished but max $MaxFinConWaitTime seconds!") if ($ComWorker{$Iam}->{numActCon});
          my $run = 1;
          $@ = undef;
          while (! $@ && $run && time < $stopTime) {$run = eval {&ThreadMain();} }
          $ComWorker{$Iam}->{run} = 0;
      }
      &sigoff(__LINE__);
      if ($exception) {
          $ComWorker{$WorkerNumber}->{CANSIG} = 0;
          mlog (0,"Error: $WorkerName: $exception");
          d("Error: $@");
          writeExceptionLog("Error: $WorkerName: $exception");
          $exception = ": $exception";
      };
      $ComWorker{$WorkerNumber}->{CANSIG} = 0;
      mlog (0,"Info: auto restart died worker $WorkerName") if ($ComWorker{$Iam}->{run} && $autoRestartDiedThreads);
      &clearDBCon();
      delete $ComWorker{$Iam}->{numActCon};
      foreach my $fh (keys %Con) {
          printallCon($fh,$exception);
          removeCrashFile($fh);
          eval{close($fh);};
          delete $Con{$fh};
          delete $SMTPSession{$fh};
      }
      foreach my $fh (keys %SocketCallsNewCon) {
          eval{close($fh);};
          delete $SocketCallsNewCon{$fh};
          delete $Con{$fh};
      }
    } while ($ComWorker{$Iam}->{run} && $autoRestartDiedThreads);
    mlog(0,"$WorkerName finished");
    d("finished work $exception");
    &printVars();
    $ComWorker{$Iam}->{finished} = 1;
    threads->exit(1);
}
