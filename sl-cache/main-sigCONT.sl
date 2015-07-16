#line 1 "sub main::sigCONT"
package main; sub sigCONT {
   $ComWorker{$WorkerNumber}->{CANSIG} = 0; $ComWorker{$WorkerNumber}->{NEVERSIG} = 1;
   my $sCsig = shift;
   local $_ = undef;
   local @_ = ();
   local $/ = undef;
   mlog_S(0,"info: $WorkerName is interrupted to get new connection") if $WorkerLog;
   d_S('interrupted');
   my $sCres;
   my $sCitime = time;
   my $sCycleTime = $ThreadCycleTime ? $ThreadCycleTime : 1;
   $sCycleTime = $sCycleTime / 1000000;
   do {
       threads->yield();
       $sCres = $tqueue->dequeue_nb();
       threads->yield();
       unless ($sCres) {
          threads->yield();
          Time::HiRes::sleep($sCycleTime);
          $ThreadIdleTime{$WorkerNumber} += $sCycleTime;
       }
   } while (! $sCres && 5 > time - $sCitime);
   if ($sCres) {
       d_S('interrupted - data from MainThread');
       $inSIG = 1;
       &ThreadGetNewCon();
       $inSIG = 0;
       d_S('returned from ThreadGetNewCon');
   } else {
       d_S('interrupted - no data from MainThread');
       mlog_S(0,"warning: $WorkerName was interrupted - but has not got the ready sign from MainThread") if $WorkerLog;
   }
   $SIG{CONT} = \&sigCONT;
   threads->yield();
   $ComWorker{$WorkerNumber}->{CANSIG} = 1; $ComWorker{$WorkerNumber}->{NEVERSIG} = 0;
   threads->yield();
}
