#line 1 "sub main::configUpdateMXACR"
package main; sub configUpdateMXACR {my ($name, $old, $new, $init)=@_;
    return unless $WorkerNumber == 0;
    $$name = $Config{$name} = $new;
    mlog(0,"AdminUpdate: MXA Cache Refresh updated from '$old' to '$new'") unless $init || $new eq $old;
    cmdToThread('cleanCacheMXA','') unless $init || $new eq $old;
}
