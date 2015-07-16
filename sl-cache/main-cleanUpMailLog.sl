#line 1 "sub main::cleanUpMailLog"
package main; sub cleanUpMailLog {
    d('cleanUpMailLog');
    return unless $MaxLogAge;
    return unless $logfile;
    return if $logfile =~ /\/?maillog\.log$/io;
    my $age = $MaxLogAge * 3600 * 24;
    my ($logdir, $logdirfile) = $logfile=~/^(.*[\/\\])?(.*?)$/o;
    $logdir = $base unless $logdir;
    return unless $logdirfile;
    mlog(0,"info: starting cleanup of old maillog files") if $MaintenanceLog >= 2;
    &ThreadMaintMain2() if $WorkerNumber == 10000;
    &cleanUpFiles($logdir,$logdirfile,$age);
    &ThreadMaintMain2() if $WorkerNumber == 10000;
    &cleanUpFiles($logdir,"b$logdirfile",$age);
}
