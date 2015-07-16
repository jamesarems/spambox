#line 1 "sub main::configUpdateSBCR"
package main; sub configUpdateSBCR {my ($name, $old, $new, $init)=@_;
    return unless $WorkerNumber == 0;
    $$name = $Config{$name} = $new;
    mlog(0,"AdminUpdate: SenderBase Cache Refresh updated from '$old' to '$new'") unless $init || $new eq $old;
    cmdToThread('cleanCacheSB','') unless $init || $new eq $old;
}
