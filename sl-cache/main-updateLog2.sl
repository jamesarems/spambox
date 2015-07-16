#line 1 "sub main::updateLog2"
package main; sub updateLog2 {my ($name, $old, $new, $init)=@_;
    return '' if $WorkerNumber;
    mlog(0,"AdminUpdate: Non Spam Logging Frequency updated from '$old' to '$new'") unless $init || $new eq $old;
    $logFreq[2] = ${$name} = $Config{$name} = $new;
    return '';
}
