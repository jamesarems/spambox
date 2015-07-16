#line 1 "sub main::configChangeRSRBSched"
package main; sub configChangeRSRBSched {
    my ($name, $old, $new, $init)=@_;

    if (! $CanUseSchedCron) {
        ${$name} = 'noschedule';
        $Config{$name} = 'noschedule';
        return '<span class="negative">***  Perl module Schedule::Cron is not installed</span>';
    }
    if ($new !~ /^noschedule$/io) {
        my @errors;
        for (split(/\|/o,$new)) {
            eval{Schedule::Cron->get_next_execution_time($_);};
            push @errors , $@ if $@;
        }
        if (! @errors) {
            $Config{$name} = $new;
            ${$name} = $new;
            mlog(0,"AdminUpdate: $name updated from '$old' to '$new'") unless $init || $new eq $old;
            return '';
        }
        mlog(0,"AdminUpdate: syntax error in $name - '$new' - @errors");
        $new = $old;
        $Config{$name} = $old;
        ${$name} = $old;
        foreach (@errors) {
            s/[\r\n]//go;
            s/ at .*//o;
        }
        my $text = join('<br />',@errors);
        return '<span class="negative">***  '.$text.'</span>';
    } else {
        mlog(0,"AdminUpdate: $name updated from '$old' to '$new'") unless $init || $new eq $old;
        $Config{$name} = 'noschedule';
        ${$name} = 'noschedule';
        return '';
    }
}
