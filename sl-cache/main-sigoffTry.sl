#line 1 "sub main::sigoffTry"
package main; sub sigoffTry {
  my $where = shift;
  threads->yield();
  return 1 if ($WorkerNumber == 0 or $WorkerNumber > 9999 or $ComWorker{$WorkerNumber}->{NEVERSIG});
  $ComWorker{$WorkerNumber}->{SIGSTATE} = $ComWorker{$WorkerNumber}->{CANSIG} == 1 ? 1 : 0;
  &sigoff($where) if ($ComWorker{$WorkerNumber}->{SIGSTATE});
  threads->yield();
  return 1;
}
