#line 1 "sub main::sigonTry"
package main; sub sigonTry {
  my $where = shift;
  threads->yield();
  return 1 if ($WorkerNumber == 0 or $WorkerNumber > 9999 or $ComWorker{$WorkerNumber}->{NEVERSIG});
  return 1 unless ($ComWorker{$WorkerNumber}->{SIGSTATE});
  $ComWorker{$WorkerNumber}->{SIGSTATE} = 0;
  &sigon($where);
  threads->yield();
  return 1;
}
