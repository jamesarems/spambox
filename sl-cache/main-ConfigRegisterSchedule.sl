#line 1 "sub main::ConfigRegisterSchedule"
package main; sub ConfigRegisterSchedule {
    my ($name,@sched) = @_;
    return if $WorkerNumber != 0;
    $ScheduleIsChanged = 1;
    if (! @sched) {
        @{$registeredSchedules{$name}} = ();
        undef @{$registeredSchedules{$name}};
        delete $registeredSchedules{$name};
    } else {
        @{$registeredSchedules{$name}} = @sched;
    }
}
