#line 1 "sub main::updateLog3"
package main; sub updateLog3 {my ($name, $old, $new, $init)=@_;
    return '' if $WorkerNumber;
    mlog(0,"AdminUpdate: Spam Logging Frequency updated from '$old' to '$new'") unless $init || $new eq $old;
    $logFreq[3] = ${$name} = $Config{$name} = $new;
    return '';
}
