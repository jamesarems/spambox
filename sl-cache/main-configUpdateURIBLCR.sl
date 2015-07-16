#line 1 "sub main::configUpdateURIBLCR"
package main; sub configUpdateURIBLCR {my ($name, $old, $new, $init)=@_;
    return unless $WorkerNumber == 0;
    $$name = $Config{$name} = $new;
    mlog(0,"AdminUpdate: URIBL Cache Refresh updated from '$old' to '$new'") unless $init || $new eq $old;
    cmdToThread('cleanCacheURI','') unless $init || $new eq $old;
}
