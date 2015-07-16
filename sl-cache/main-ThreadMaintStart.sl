#line 1 "sub main::ThreadMaintStart"
package main; sub ThreadMaintStart {
    $WorkerNumber = shift;
    threads->detach();
    close STDOUT;
    close STDERR;
    close STDIN;
    unloadHighThreadModules() if $undefMEM;
    unloadSub 'write_rebuild_module' if $undefMEM;
    if ($CanUseBerkeleyDB) {
        eval('use BerkeleyDB;');
        if ($VerBerkeleyDB lt '0.42') {
            *{'BerkeleyDB::_tiedHash::CLEAR'} = *{'main::BDB_CLEAR'};
        }
        *{'BerkeleyDB::_tiedHash::STORE'} = *{'main::BDB_STORE'};
        *{'BerkeleyDB::_tiedHash::DELETE'} = *{'main::BDB_DELETE'};
    }
    my $exception = '';
    eval{%BlockRepForwQueue = %{Storable::retrieve("$base/BlockRepForwQueue.store")}} if -e "$base/BlockRepForwQueue.store";
    do {
      $exception = '';
      $calledfromThread = 1;
      $WorkerName = "Worker_$WorkerNumber";
      &initGlobalThreadVar();
      &initDBHashes();
      &initPrivatHashes();
      &initFileHashes('AdminGroup');  # AdminGroup is never shared;
      mlog(0,"$WorkerName started");
      &sigCentralSet();
      eval{while ($ComWorker{$WorkerNumber}->{run}) {&ThreadYield();&ThreadMaintMain();}1;}
      or do {
          mlog (0,"Error: $WorkerName: $@");
          d("Error: $@");
          writeExceptionLog("Error: $WorkerName: $@");
          $exception = ": $@";
      };
      mlog (0,"Info: auto restart died worker $WorkerName") if ($ComWorker{$WorkerNumber}->{run} && $autoRestartDiedThreads);
      foreach (keys %RunTaskNow) {
          $RunTaskNow{$_} = '';
      }
      if (! $ComWorker{$WorkerNumber}->{run}) {
          processMaintCMDQueue();
      } else {
          while ($cmdQueue->pending()) {
              my $parm;
              d('clean CMD from cmdQueue');
              threads->yield();
              my $item = $cmdQueue->dequeue_nb(1);
              threads->yield();
              my ($sub,$parmnum) = $item =~ /^sub\(([^\)]+)\)(.*)/o;
              mlog(0,"info: cleaned command '$sub' from commandqueue");
          }
          { lock(%cmdQParm) if is_shared(%cmdQParm); %cmdQParm = ();}
      }
      &DMARCgenReport(1) if    $ValidateSPF       # send the DMARK reports if %DMARCpol and %DMARCrec are not in BDB
                            && $DoDKIM
                            && $DMARCReportFrom
                            && ! ($ComWorker{$WorkerNumber}->{run} && $autoRestartDiedThreads)
                            && ! (exists $BerkeleyDBHashes{DMARCpol} && exists $BerkeleyDBHashes{DMARCrec});
      &clearDBCon();
    } while ($ComWorker{$WorkerNumber}->{run} && $autoRestartDiedThreads);
    if (scalar keys(%BlockRepForwQueue)) {
        eval{Storable::store(\%BlockRepForwQueue, "$base/BlockRepForwQueue.store");};
    } else {
        unlink("$base/BlockRepForwQueue.store");
    }
    mlog(0,"$WorkerName finished");
    d("finished work $exception");
    &printVars();
    $ComWorker{$WorkerNumber}->{finished} = 1;
    threads->exit();
}
