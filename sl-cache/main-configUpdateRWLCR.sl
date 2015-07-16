#line 1 "sub main::configUpdateRWLCR"
package main; sub configUpdateRWLCR {my ($name, $old, $new, $init)=@_;
    return unless $WorkerNumber == 0;
    $$name = $Config{$name} = $new;
    mlog(0,"AdminUpdate: RWL Cache Refresh updated from '$old' to '$new'") unless $init || $new eq $old;
    cmdToThread('cleanCacheRWL','') unless $init || $new eq $old;
}
