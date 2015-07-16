#line 1 "sub main::CleanWhitelist"
package main; sub CleanWhitelist {
  d('CleanWhitelist');
  &ThreadMaintMain2() if $WorkerNumber == 10000;
  mlog(0,"cleaning up whitelist database ...") if $MaintenanceLog;
  my $t=time;
  my $keys_before = my $keys_deleted = 0;
  my $maxtime = $MaxWhitelistDays * 3600 * 24;
  if ($MaxWhitelistDays) {
      while (my ($k,$v)=each(%Whitelist)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $keys_before % 100;
        $keys_before++;
        $v = 0 unless $v;
        next if $v < 1000000000;
        my $delta = $t-$v;
        if ($delta >= $maxtime or ($k=~/,/o && $v > 9999999999 && $delta + 9999999999 >= $maxtime)) {
          delete $Whitelist{$k};
          $v -= 9999999999 if $v > 9999999999;
          mlog(0,"Admininfo: $k removed from whitelistdb - entry was outdated (" . &timestring($v,'') . ')') if $MaintenanceLog >= 2;
          $keys_deleted++;
        }
      }
      mlog(0,"cleaning whitelist database finished: keys before=$keys_before, deleted=$keys_deleted") if $keys_before && $MaintenanceLog;
  }
  &SaveWhitelistOnly();
}
