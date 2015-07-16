#line 1 "sub main::ConfigChangeLogfile"
package main; sub ConfigChangeLogfile {my ($name, $old, $new, $init)=@_;
    close $LOG if $logfile;
    close $LOGBR if $logfile && $ExtraBlockReportLog;
    $logfile=$Config{logfile}=$new unless $WorkerNumber;
    if($logfile && (open($LOG,'>>',"$base/$logfile"))) {
        binmode $LOG;
        $LOG->autoflush;
        print $LOG $UTF8BOM;
    }
    my ($logdir, $logdirfile) = $logfile =~ /^(.*[\/\\])?(.*?)$/o;
    $blogfile = $logdir . "b$logdirfile";
    if($logfile && $ExtraBlockReportLog && (open($LOGBR,'>>',"$base/$blogfile"))) {
        binmode $LOGBR;
        $LOGBR->autoflush;
        print $LOGBR $UTF8BOM;
    }
    mlog(0,"AdminUpdate: log file changed to '$new' from '$old'");
    '';
}
