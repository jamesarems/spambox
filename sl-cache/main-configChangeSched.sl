#line 1 "sub main::configChangeSched"
package main; sub configChangeSched {
    my ($name, $old, $new, $init, $desc) = @_;
    return if $WorkerNumber != 0;
    
    if (exists $ScheduleMap{$name}) {
        my $n;
        if ( isSched($new) ) {
            if (! $CanUseSchedCron) {
                my $error;
                if (isSched($old) ) {
                    mlog(0,"error: $name was set to zero - missing Schedule::Cron");
                    $error = ' - disabled $name - old value was $old';
                    $old = 0;
                }
                ${$name} = $Config{$name} = $old;
                return '<span class="negative">***  Perl module Schedule::Cron is not installed$error</span>';
            }
            (my $t = getNextSched($new,$desc))
            or do {
                ${$name} = $Config{$name} = $old;
                return "<span class=\"negative\"><b>*** Invalid Schedule: '$qs{$name}'</b></span>";
              };
            my @map = @{$ScheduleMap{$name}};
            while (@map) {
                my $d = shift @map;   # dummy shift
                $n = shift @map;
                ${$n} = $t;
            }
        } elsif ( isSched($old) ) {
            my @map = @{$ScheduleMap{$name}};
            while (@map) {
                my $t = shift @map;
                $n = shift @map;
                ${$n} = time + $new * $t;
            }
        } else {
            my @map = @{$ScheduleMap{$name}};
            while (@map) {
                my $t = shift @map;
                $n = shift @map;
                ${$n} += ($new - $old) * $t;
            }
        }
        mlog(0,"AdminUpdate: $name updated from '$old' to '$new'") unless $init || $new eq $old;
        mlog(0,"info: (re)scheduled $name -> $n for " . timestring(${$n})) if $MaintenanceLog > 2;
    } else {
        return "<span class=\"negative\"><b>*** code error '$name' is not a registered schedule</b></span><br />";
    }
    ${$name} = $Config{$name} = $new;
    return '';
}
