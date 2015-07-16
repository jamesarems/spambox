#line 1 "sub main::ThreadGoSleep"
package main; sub ThreadGoSleep {
      my $Iam = shift;
      if ($ComWorker{$Iam}->{rereadconfig}) {
          &ThreadYield();
          return;
      }
      $ComWorker{$Iam}->{issleep} = 1;      # tell all we go sleep
      $ComWorker{$Iam}->{inerror} = 0;     # reset the error sign
      my @read = $readable->handles();
      while (@read) {
         my $fh = shift @read;
         unpoll($fh,$readable);
         mlog(0,"error: $WorkerName removed Ghosthandle read: $fh , please report") if $ConnectionLog > 2;
         done2($fh);
      }
      &ConDone();
      my @write = $writable->handles();
      while (@write) {
         my $fh = shift @write;
         unpoll($fh,$writable);
         mlog(0,"error: $WorkerName removed Ghosthandle write: $fh , please report") if $ConnectionLog > 2;
         done2($fh);
      }
      &ConDone();
      while ( my ($fh,$v) = each %SMTPSession) {
         mlog(0,"error: $WorkerName removed Ghosthandle SMTPSession: $fh , please report") if $ConnectionLog > 2;
         done2($fh);
      }
      &ConDone();
      while ( my ($fh,$v) = each %Con) {
         done2($fh) if "$fh" =~ /socket/io;
      }
      &ConDone();
      mlog(0,"$WorkerName prepare to sleep") if ($WorkerLog >= 2 && ! $thread_nolog && $ComWorker{$Iam}->{run} != 2);
      %Con=();
      undef %Con;
      %Fileno = ();
      undef %Fileno;
      return if $ComWorker{$Iam}->{run} == 2;  # we got a Quit - there is nothing more to do
      d('sleeping');
      mlog(0,"$WorkerName will sleep now") if ($WorkerLog && (! $thread_nolog || $WorkerLog == 3));
      my $mem = $showMEM ? printMem() : 0;
      mlog(0,"info: worker memory$mem") if $mem && $MaintenanceLog > 2;
      $WorkerLastAct{$Iam} = time;
      my $st = Time::HiRes::time();
      threads->yield;
      my $res = $tqueue->dequeue(1);         # wait until anyone wakes us up;
      threads->yield;
      $ComWorker{$Iam}->{issleep} = 0;      # tell all we are not sleeping
      threads->yield;
      $ThreadIdleTime{$Iam} += Time::HiRes::time() - $st;
      threads->yield;
      $thread_nolog = 0;
      $thread_nolog = 1 if ( $res eq 'status' );
      mlog(0,"$WorkerName wakes up") if ($WorkerLog && (! $thread_nolog || $WorkerLog == 3));
      $mem = $showMEM ? printMem() : 0;
      mlog(0,"info: worker memory$mem") if $mem && $MaintenanceLog > 2;
      $WorkerLastAct{$Iam} = time;
      threads->yield;
      &ThreadGetNewCon();
      &NewSMTPConCall();
}
