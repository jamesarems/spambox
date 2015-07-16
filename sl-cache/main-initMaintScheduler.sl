#line 1 "sub main::initMaintScheduler"
package main; sub initMaintScheduler {
    my ($name, $old, $new, $init, $desc) = @_;
    if ($name eq 'BlockReportFile') {
        ${$name}=$Config{$name};
        my $fil;
        if (${$name} =~ /^ *file: *(.+)/io) {
            $fil = $1;
            $fil = "$base/$fil" if $fil!~/^\Q$base\E/io;
            $FileUpdate{"$fil$name"} = $FileUpdate{$fil} = ftime($fil);
        }
#        $fil = "$base/files/UserBlockReportQueue.txt";
#        $FileUpdate{$fil} = ftime($fil);
    }
    return if $WorkerNumber != 0;
    %ScheduledTask = ();
    BlockReportGenSched();
    for (keys %registeredSchedules) { addSched(@{$registeredSchedules{$_}}); }
    $ScheduleIsChanged = 0;
    return '';
}
