#line 1 "sub main::SaveDelaydb"
package main; sub SaveDelaydb {
  if ($delaydb !~ /DB:/o) {
    mlog(0,"saving delaying records") if $MaintenanceLog;
    &SaveHash('Delay');
    &SaveHash('DelayWhite');
  }
}
