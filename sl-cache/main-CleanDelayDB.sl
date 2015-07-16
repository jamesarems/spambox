#line 1 "sub main::CleanDelayDB"
package main; sub CleanDelayDB {
  d('CleanDelayDB');
  &ThreadMaintMain2() if $WorkerNumber == 10000;
  mlog(0,"cleaning up delaying databases ...") if $MaintenanceLog;
  my $t=time;
  my $keys_before=my$keys_deleted=0;
  my $maxtime = $DelayEmbargoTime*60+$DelayWaitTime*3600;
  while (my ($k,$v)=each(%Delay)) {
    &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $keys_before % 100;
    $keys_before++;
    if ($t-$v>=$maxtime) {
      delete $Delay{$k};
      $keys_deleted++;
    }
  }
  mlog(0,"cleaning delaying database (triplets) finished: keys before=$keys_before, deleted=$keys_deleted") if $MaintenanceLog && $keys_before != 0;
  $keys_before=$keys_deleted=0;
  $maxtime = $DelayExpiryTime*24*3600;
  while (my ($k,$v)=each(%DelayWhite)) {
    $keys_before++;
    if ($t-$v>=$maxtime) {
      delete $DelayWhite{$k};
      $keys_deleted++;
    }
  }
  mlog(0,"cleaning delaying database (safelisted tuplets) finished: keys before=$keys_before, deleted=$keys_deleted") if $MaintenanceLog && $keys_before != 0;
  &SaveDelaydb();
}
