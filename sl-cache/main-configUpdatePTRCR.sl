#line 1 "sub main::configUpdatePTRCR"
package main; sub configUpdatePTRCR {my ($name, $old, $new, $init)=@_;
    return unless $WorkerNumber == 0;
    $$name = $Config{$name} = $new;
    mlog(0,"AdminUpdate: PTR Cache Refresh updated from '$old' to '$new'") unless $init || $new eq $old;
    cmdToThread('cleanCachePTR','') unless $init || $new eq $old;
}
