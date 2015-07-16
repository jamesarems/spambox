#line 1 "sub main::addSched"
package main; sub addSched {
    my ($sched,$run,$desc,$parm) = @_;
    return unless $CanUseSchedCron;
    return unless $sched;
    return unless $desc;
    $run ||= [[caller(unpack("A1",$X)-1)]->[unpack("A1",$X)+1]];
    my $nextrun = getNextSched($sched,$desc);
    return unless $nextrun;
    return if $nextrun < time;
    foreach (keys %ScheduledTask) {
        if (   eval{$ScheduledTask{$_}->{Run} eq $run;}
            && $ScheduledTask{$_}->{Parm} eq $parm
            && $ScheduledTask{$_}->{Desc} eq $desc)
        {
            eval{$ScheduledTask{$_}->{Nextrun} = $nextrun;};
            $ScheduledTask{$_}->{Schedule} = $sched;
            $nextrun = timestring($nextrun);
            mlog(0,"info: changed schedule : $desc - to : $parm - at : $sched - next run is at : $nextrun") if $MaintenanceLog;
            return;
        }
    }
    my $c = 1;
    while (exists $ScheduledTask{$c}) {$c++;}
    $ScheduledTask{$c} = &share({});
    eval{$ScheduledTask{$c}->{Nextrun} = $nextrun;};
    $ScheduledTask{$c}->{Schedule} = $sched;
    $ScheduledTask{$c}->{Run} = $run;
    $ScheduledTask{$c}->{Parm} = $parm;
    $ScheduledTask{$c}->{Desc} = $desc;
    $nextrun = timestring($nextrun);
    mlog(0,"info: added schedule : $desc - for : $parm - at : $sched - next run is at : $nextrun") if $MaintenanceLog;
}
