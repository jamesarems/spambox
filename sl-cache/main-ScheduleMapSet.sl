#line 1 "sub main::ScheduleMapSet"
package main; sub ScheduleMapSet {
    my ( $map, $next ) = @_;
    if ($map) {
        my @val = @{$ScheduleMap{$map}};
        while (@val) {
            my $t = shift @val;
            my $var = shift @val;
            next if $next && $next ne $var;
            setLastSchedTime($map, ${$var});
            ${$var} = max( getSchedTime($map,$t), time);
            mlog(0,"info: (re)scheduled $map -> $var for " . timestring(${$var})) if $MaintenanceLog > 2;
        }
    } else {
        while (my ($k,$v) = each %ScheduleMap) {
            my @val = @{$v};
            while (@val) {
                my $t = shift @val;
                my $var = shift @val;
                my $last = getLastSchedTime($k);
                my $bt = isSched(${$k}) ? 0 : $last;
                ${$var} = max( getSchedTime($k,$t,$bt), time);
                mlog(0,"info: (re)scheduled $k -> $var for " . timestring(${$var})) if $MaintenanceLog > 2;
            }
        }
    }
    saveHashToFile( "$base/scheduleHistory", \%LastSchedRun );
    return;
}
