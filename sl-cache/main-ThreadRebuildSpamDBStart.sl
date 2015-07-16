#line 1 "sub main::ThreadRebuildSpamDBStart"
package main; sub ThreadRebuildSpamDBStart {
    my $Iam = shift;
    $WorkerNumber = $Iam;
    threads->detach();
    close STDOUT;
    close STDERR;
    close STDIN;
    unloadHighThreadModules() if $undefMEM;
    undef $GPBinstallLib;
    undef $GPBmodTestList;
    undef $GPBCompLibVer;
    our $cleanHMM;
    if ($CanUseBerkeleyDB) {
        eval('use BerkeleyDB;');
        if ($VerBerkeleyDB lt '0.42') {
            *{'BerkeleyDB::_tiedHash::CLEAR'} = *{'main::BDB_CLEAR'};
        }
        *{'BerkeleyDB::_tiedHash::STORE'} = *{'main::BDB_STORE'};
        *{'BerkeleyDB::_tiedHash::DELETE'} = *{'main::BDB_DELETE'};
    }
    my $exception = '';
    do {
      $exception = '';
      $cleanHMM = '';
      $calledfromThread = 1;
      $WorkerName = "Worker_$Iam";
      &initGlobalThreadVar();
      &initDBHashes();
      &initPrivatHashes();
      &initFileHashes('AdminGroup');  # AdminGroup is never shared;
      mlog(0,"$WorkerName started");

      &sigCentralSet();
      $SIG{INT}=\&sigToMainThread;
      $SIG{TERM}=\&sigToMainThread;
      $SIG{HUP}=\&sigToMainThread;
      $SIG{USR1}=\&sigToMainThread;
      $SIG{USR2}=\&sigToMainThread;
      $SIG{NUM07}=\&sigToMainThread;

      eval{while ($ComWorker{$Iam}->{run}) {&ThreadRebuildSpamDBMain();}1;}
      or do {
          mlog (0,"Error: $WorkerName: $@");
          d("Error: $@");
          writeExceptionLog("Error: $WorkerName: $@");
          $exception = $@;
      };
      mlog (0,"Info: auto restart died worker $WorkerName") if ($ComWorker{$Iam}->{run} && $autoRestartDiedThreads);
      $RunTaskNow{RunRebuildNow} = '';
      &clearDBCon();
    } while ($ComWorker{$Iam}->{run} && $autoRestartDiedThreads);
    mlog(0,"$WorkerName finished");
    d("finished work $exception");
    &printVars();
    $ComWorker{$Iam}->{finished} = 1;
    threads->exit();
}
