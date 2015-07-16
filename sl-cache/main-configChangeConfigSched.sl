#line 1 "sub main::configChangeConfigSched"
package main; sub configChangeConfigSched {
    my ($name, $old, $new, $init, $desc) = @_;
    return if $WorkerNumber != 0;
    mlog(0,"AdminUpdate: $name updated from '$old' to '$new'") unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new;
    my @new = checkOptionList($new,$name,$init);
    if ($new[0] =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new[0]);
    }

    # remove all old schedules
    my $s = 0;
    foreach (keys %registeredSchedules) {
        ConfigRegisterSchedule($_,()) if /^ConfigChangeSchedule/o;
        mlog(0,"info: removed schedule $_") if $MaintenanceLog > 2;
        $s++;
    }
    mlog(0,"info: removed $s config change schedules") if $MaintenanceLog && $s;
    
    # add the new schedules
    my $l = 0;
    $s = 0;
    while (@new) {
        my $line = shift @new;
        my ($var,$val);
        $l++;
        $line =~ s/^\s*//o;
        $line =~ s/[\r\n\s]+$//o;
        next unless $line;
        
        my ($sched,$config) = $line =~ /^($ScheduleRe(?:\|$ScheduleRe)*)\s*(.+)\s*$/o;
        if (! $sched) {
            mlog(0,"error: $name - line $l of file $new contains not a valid schedule and/or configuration variable definition");
            next;
        }
        if ($config !~ /^\&/o) {
            ($var,$val) = split(/\s*:=\s*/o, $config, 2);
            if (! $var) {
                mlog(0,"error: $name - line $l of file $new contains no configuration variable definition");
                next;
            }
            if (! exists $Config{$var} && ! defined $$var) {
                mlog(0,"error: $name - line $l of file $new contains no valid configuration variable definition - ($var)");
                next;
            }
            if (exists $Config{$var}) {
                if ($ConfigArray[$ConfigNum{$var}]->[3] eq \&textnoinput or $ConfigArray[$ConfigNum{$var}]->[3] eq \&passnoinput) {
                    mlog(0,"error: $name - line $l of file $new tries to change the protected configuration variable $var - schedule is ignored");
                    next;
                }
                my $re = $ConfigArray[$ConfigNum{$var}]->[5];
                if ($val !~ /$re/i) {
                    mlog(0,"error: $name - line $l of file $new contains not a valid value for the configuration variable $var - $ConfigNum{$var} - $re");
                    next;
                }
            }
        } else {
            ($var,$val) = $config =~ /^(\&[a-z0-9_]+)(.*)$/io;
        }
        my @sched = ($sched,'push_ChangeConfigVar',"ConfigChangeSchedule_".$l."_$var",$var.':='.$val);
        ConfigRegisterSchedule("ConfigChangeSchedule_".$l, @sched);
        mlog(0,"info: added schedule ConfigChangeSchedule_".$l."_$var") if $MaintenanceLog > 1;
        $s++;
    }
    mlog(0,"info: registered $s config change schedules") if $MaintenanceLog && $s;
    mlog(0,"warning: $name - the schedules are registered but will not run, because the module Schedule::Cron is not available!") if $s && ! $CanUseSchedCron;
    return '';
}
