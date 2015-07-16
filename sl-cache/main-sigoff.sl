#line 1 "sub main::sigoff"
package main; sub sigoff {
  my $where = shift;
  threads->yield();
  return 1 if ($WorkerNumber == 0 or $WorkerNumber > 9999 or $ComWorker{$WorkerNumber}->{NEVERSIG});
  my @m = localtime();
  my $m = $m[5]-100 . '-' . $m[3] . '-' . $m[4] . " $m[2]:$m[1]:$m[0] " . Time::HiRes::time();
  (my $package, my $file, my $line, my $Subroutine, my $HasArgs, my $WantArray, my $EvalText, my $IsRequire) = caller(1);
  if ($ComWorker{$WorkerNumber}->{CANSIG} == 0 && $WorkerLog >= 2) {
      threads->yield();
      mlog(0,"code error: sigoff in $package, $file, $line, $Subroutine, $HasArgs, $WantArray, $EvalText, $IsRequire at $m - $where");
      mlog(0,"code error: $lastsigoff{$WorkerNumber}");
  }
  $lastsigoff{$WorkerNumber} = "last sigoff in $package, $file, $line, $Subroutine, $HasArgs, $WantArray, $EvalText, $IsRequire at $m - $where";
  threads->yield();
  my $ws = $willSIG;                           # is MainThread waiting to interrupt ?
  threads->yield;
  if (! $ws || $ws > 11000) {               # no or other Worker is still waiting for interrupt
      $ComWorker{$WorkerNumber}->{CANSIG} = 0;
      return 1;
  }
  my $maxwait = 10;
  my $stime = time;
  threads->yield;
  $willSIG = 11000 + $WorkerNumber;      # tell all that we are waiting for interrupt
  threads->yield;
  mlog(0,"info: $WorkerName is waiting for interrupt from MainThread : (SIG-OFF)") if ($WorkerLog >= 2);
  threads->yield();
  while ($ws > 0 && time - $stime < $maxwait) {                         # wait for interrupt to freeup MainThread
      threads->yield;
      $ws = $willSIG;
      &ThreadYield();
  }
  mlog(0,"info: $WorkerName was waiting 10 seconds for interrupt from MainThread - and has not got one: (SIG-OFF)") if ($WorkerLog >= 2 && $ws > 0);
  $ComWorker{$WorkerNumber}->{CANSIG} = 0;
  threads->yield();
  return 1;
}
