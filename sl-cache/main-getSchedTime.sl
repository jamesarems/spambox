#line 1 "sub main::getSchedTime"
package main; sub getSchedTime {
    my ($sched,$factor,$basetime) = @_;
    $basetime ||= time;
    $factor ||= 1;
    return 0 unless $sched;
    my $desc = $sched;
    $sched = ${$sched};
    return ( isSched($sched) && defined *{'yield'} ? getNextSched($sched,$desc,$basetime) : $sched * $factor + $basetime);
}
