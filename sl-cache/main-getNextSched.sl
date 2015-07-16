#line 1 "sub main::getNextSched"
package main; sub getNextSched {
    my ($sched,$desc,$time) = @_;
    return unless $CanUseSchedCron;
    return unless $sched;
    return unless $desc;
    $time ||= time;
    my $cron;
    my @schedule;
    for ( split(/\|/o,$sched) ) {
        s/^s+//o;
        s/s+$//o;
        eval{
            $cron = Schedule::Cron->get_next_execution_time($_,$time);
            if ($cron =~ /^\d+$/io) {
                push @schedule, $cron;
            } else {
                mlog(0,"error: Schedule entry '$_' for $desc is not valid");
            }
            1;
        } or do {
            mlog(0,"error: Schedule entry '$_' for $desc is not valid - $@");
            next;
        }
    }
    return 0 unless scalar @schedule;
    return min( @schedule );
}
