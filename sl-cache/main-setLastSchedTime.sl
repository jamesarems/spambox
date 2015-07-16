#line 1 "sub main::setLastSchedTime"
package main; sub setLastSchedTime {
    my ($var, $time) = @_;
    $LastSchedRun{$var} = $time;
    return;
}
