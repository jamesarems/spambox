#line 1 "sub main::RemovePid"
package main; sub RemovePid {
 if ($pidfile) {
  d('RemovePid');
  close $PIDH;
  unlink("$base/$pidfile") or mlog(0,"warning: unable to delete $base/$pidfile");
 }
}
