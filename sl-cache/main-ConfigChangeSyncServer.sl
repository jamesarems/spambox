#line 1 "sub main::ConfigChangeSyncServer"
package main; sub ConfigChangeSyncServer {my ($name, $old, $new, $init)=@_;
    return '' if $new eq $old && ! $init;
    return '<span class="negative"></span>' if $WorkerNumber != 0;
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    return &ConfigChangeEnableCFGSync('enableCFGShare', $enableCFGShare, '', '') if (! $new || $init);
    mlog(0,"AdminUpdate: $name changed from $old to $new") if $new ne $old;
    %subOIDLastLoad = ();
    if (&syncLoadConfigFile()) {
        return '';
    } else {
        return "<span class=\"positive\">updated - but sync-config-file was still not loaded - sync config is still incomplete</span>";
    }
}
