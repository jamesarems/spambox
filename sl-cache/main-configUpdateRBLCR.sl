#line 1 "sub main::configUpdateRBLCR"
package main; sub configUpdateRBLCR {my ($name, $old, $new, $init)=@_;
    return unless $WorkerNumber == 0;
    $$name = $Config{$name} = $new;
    mlog(0,"AdminUpdate: RBL Cache Refresh updated from '$old' to '$new'") unless $init || $new eq $old;
    cmdToThread('cleanCacheRBL','') unless $init || $new eq $old;
}
