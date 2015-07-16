#line 1 "sub main::isSched"
package main; sub isSched {
    my $sched = shift;
    return $sched =~ /^$ScheduleRe(?:\|$ScheduleRe)*$/o;
}
