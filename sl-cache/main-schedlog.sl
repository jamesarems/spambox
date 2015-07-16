#line 1 "sub main::schedlog"
package main; sub schedlog {
    my($lvl,$msg) = @_;
    my @Levels = ('Info', 'Warning', 'Error');
    mlog(0,$Levels[$lvl].": $msg") if ($ScheduleLog >= 2 or ($ScheduleLog && $lvl > 0));
}
