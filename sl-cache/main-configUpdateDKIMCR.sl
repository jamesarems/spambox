#line 1 "sub main::configUpdateDKIMCR"
package main; sub configUpdateDKIMCR {my ($name, $old, $new, $init)=@_;
    return unless $WorkerNumber == 0;
    $$name = $new;
    $Config{$name} = $new;
    mlog(0,"AdminUpdate: DKIM Cache Refresh updated from '$old' to '$new'") unless $init || $new eq $old;
    cmdToThread('cleanCacheDKIM','') unless $init || $new eq $old;
}
