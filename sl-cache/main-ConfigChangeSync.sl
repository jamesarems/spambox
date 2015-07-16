#line 1 "sub main::ConfigChangeSync"
package main; sub ConfigChangeSync {my ($name, $old, $new, $init)=@_;
    return '' if $new eq $old && ! $init;
    return '<span class="negative"></span>' if $WorkerNumber != 0;
    $Config{$name} = $new;
    ${$name} = $new;
    return '' if $init;
    my $text = ($name eq 'syncCFGPass') ? '' : "from $old to $new";
    mlog(0,"AdminUpdate: $name changed $text") if $new ne $old;
    %subOIDLastLoad = ();
    if (&syncLoadConfigFile()) {
        return '';
    } else {
        return "<span class=\"positive\">updated - but sync-config-file was still not loaded - sync config is still incomplete</span>";
    }
}
