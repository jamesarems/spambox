#line 1 "sub main::ConfigChangeLogRollDays"
package main; sub ConfigChangeLogRollDays {
    my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: $name changed to '$new' from '$old'") unless ($init || $new eq $old);

    if ($WorkerNumber == 0) {
        ${$name} = $Config{$name} = $new;
        $mlogLastT = 0;
    }
    return '';
}
