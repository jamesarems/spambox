#line 1 "sub main::configChangeRestartEvery"
package main; sub configChangeRestartEvery {
    my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: RestartEvery updated from '$old' to '$new'") unless ($init || $new eq $old);
    return '' if $new eq $old;
    $RestartEvery = $new;
    $Config{RestartEvery} = $new;
    if ($new) {
        $endtime = time + $RestartEvery;
        mlog(0,"AdminUpdate: next restart is scheduled in " . &getTimeDiff($endtime - time));
    } else {
        $endtime = 999999999;
    }
    return '';
}
