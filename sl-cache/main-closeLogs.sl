#line 1 "sub main::closeLogs"
package main; sub closeLogs {
    $@ = '';
    $! = '';
    if ($ExtraBlockReportLog && -e "$base/$blogfile") {
        eval{$LOGBR->close;} || eval{close $LOGBR;};
        if (-e "$base/$blogfile" && ($! || $@)) {
            print "error: unable to close $base/$blogfile - $! - $@\n";
            print $LOG "error: unable to close $base/$blogfile - $! - $@\n";
        }
    }
    $@ = '';
    $! = '';
    eval {$LOG->close;} || eval {close $LOG;};
    if (-e "$base/$logfile" && ($! || $@)) {
        print "error: unable to close $base/$logfile - $! - $@\n";
        print $LOG "error: unable to close $base/$logfile - $! - $@\n";
    }
    eval{$DEBUG->close;} || eval{close $DEBUG;} if fileno($DEBUG);
}
