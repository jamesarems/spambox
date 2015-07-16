#line 1 "sub main::configChangeNumThreads"
package main; sub configChangeNumThreads {
    my ($name, $old, $new, $init, $auto)=@_;
    return if $WorkerNumber != 0;
    $auto = 'Admin' unless ($auto eq 'Auto');
    
    unless (($init || $new eq $old) && $new != 0) {
        mlog(0,$auto."Update: SMTP-Threadnumber updated from '$old' to '$new' - reset performance counters");

        $TransferInterrupt =
        $TransferInterruptTime =
        $TransferNoInterruptTime =
        $TransferTime =
        $TransferCount = 0;

        $PerfStartTime = time;
    }
    if ($new > $old) {
        mlog(0,$auto."Update: request to change SMTP-Threadnumber to $new (changed from $old) -- SPAMBOX-Restart is recommended!");
#        $NumComWorkers = $new;
        $Config{$name} = $new;
        return "<span class=\"positive\"> - NumComWorkers increased - SPAMBOX-Restart is required</span><script type=\"text/javascript\">alert(\'NumComWorkers increased - SPAMBOX-Restart is required\');</script>";
    }
    if ($new == 0) {
        mlog(0,$auto."Update: request to change SMTP-Threadnumber to 0 (changed from $old) -- value 0 is not permitted for NumComWorkers>");
        return "<span class=\"negative\"> - value 0 is not permitted for NumComWorkers</span><script type=\"text/javascript\">alert(\'value 0 is not permitted for NumComWorkers\');</script>";
    }
    for ( my $i = $old; $i > $new; $i--) {
        tellThreadQuit($i);
        delete $Threads{$i};
    }
    $NumComWorkers = $Config{$name} = $new;
    mlog(0,$auto."Update: request to change SMTP-Threadnumber to $new (changed from $old) - Restart required to freeup memory!");
    return "<span class=\"positive\"> - SPAMBOX-Restart is required to freeup memory</span><script type=\"text/javascript\">alert(\'NumComWorkers changed - SPAMBOX-Restart is required to freeup memory\');</script>";
}
