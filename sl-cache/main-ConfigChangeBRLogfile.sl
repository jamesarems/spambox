#line 1 "sub main::ConfigChangeBRLogfile"
package main; sub ConfigChangeBRLogfile {my ($name, $old, $new, $init)=@_;
    close $LOGBR if $logfile && $ExtraBlockReportLog;
    $ExtraBlockReportLog=$new;
    $Config{ExtraBlockReportLog} = $new;
    my ($logdir, $logdirfile) = $logfile =~ /^(.*[\/\\])?(.*?)$/o;
    $blogfile = $logdir . "b$logdirfile";
    if($logfile && $ExtraBlockReportLog && (open($LOGBR,'>>',"$base/$blogfile"))) {
        binmode $LOGBR;
        print $LOGBR $UTF8BOM;
        $LOGBR->autoflush;
    }
    mlog(0,"AdminUpdate: ExtraBlockReportLog changed to '$new' from '$old'");
    '';
}
