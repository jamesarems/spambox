#line 1 "sub main::configUpdateBDNSCR"
package main; sub configUpdateBDNSCR {my ($name, $old, $new, $init)=@_;
    return unless $WorkerNumber == 0;
    $$name = $Config{$name} = $new;
    mlog(0,"AdminUpdate: Backscatter-DNS Cache Refresh updated from '$old' to '$new'") unless $init || $new eq $old;
    cmdToThread('cleanCacheBackDNS','') unless $init || $new eq $old;
}
