#line 1 "sub main::getLastSchedTime"
package main; sub getLastSchedTime {
    my $var = shift;
    if (exists $LastSchedRun{$var}) {
        return $LastSchedRun{$var};
    } else {
        my $t = time;
        setLastSchedTime($var,$t);
        return $t;
    }
}
