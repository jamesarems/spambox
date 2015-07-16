#line 1 "sub main::RunTask"
package main; sub RunTask {
    my $task = shift;
    mlog(0,"error: no task defined") && return unless $task;
    mlog(0,"error: no such task found - $task") && return unless exists $Config{$task};
    mlog(0,"error: Task ($task) found - but this task could not be started externally") && return if $ConfigArray[$ConfigNum{$task}]->[6] ne 'ConfigChangeRunTaskNow';
    my $ret = ConfigChangeRunTaskNow($task, '', '1', '');
    mlog(0,"failed to start task $task") if $ret !~ /task was started/o;
    return;
}
