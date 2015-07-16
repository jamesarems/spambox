#line 1 "sub main::configUpdateSPFCR"
package main; sub configUpdateSPFCR {my ($name, $old, $new, $init)=@_;
    return unless $WorkerNumber == 0;
    $$name = $Config{$name} = $new;
    mlog(0,"AdminUpdate: SPF Cache Refresh updated from '$old' to '$new'") unless $init || $new eq $old;
    cmdToThread('cleanCacheSPF','') unless $init || $new eq $old;
}
