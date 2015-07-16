#line 1 "sub main::openLogs"
package main; sub openLogs {
# open the logfile
  my $e = $@;
  local $! = '';
  if($logfile) {
      my $append = -e "$base/$logfile";
      if (open($LOG,'>>',"$base/$logfile")) {
          binmode $LOG;
          $LOG->autoflush;
          if (! $append) {
              print $LOG $UTF8BOM;
              mlog(0,"running SPAMBOX version $main::MAINVERSION");
          }
      }
  }
  if($logfile && $ExtraBlockReportLog) {
      my $append = -e "$base/$blogfile";
      if (open($LOGBR,'>>',"$base/$blogfile")) {
          binmode $LOGBR;
          $LOGBR->autoflush;
          print $LOGBR $UTF8BOM unless $append;
      }
  }
  if($debug) {
      my $file = "$base/debug/".time.".dbg";
      open($DEBUG, '>', "$file");
      binmode($DEBUG);
      $DEBUG->autoflush;
      print $DEBUG $UTF8BOM;
      print $DEBUG "running SPAMBOX version: $main::MAINVERSION\n\n";
      mlog(0,"info: starting general debug mode to file $file");
  }
  $@ = $e;
}
