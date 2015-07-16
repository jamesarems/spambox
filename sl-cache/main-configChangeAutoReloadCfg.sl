#line 1 "sub main::configChangeAutoReloadCfg"
package main; sub configChangeAutoReloadCfg {
    my ($name, $old, $new, $init)=@_;

    mlog(0,"AdminUpdate: $name changed from '$old' to '$new'") unless $init || $new eq $old;
    return '' if($init or $old eq $new);
    if ($new) {
        $spamboxCFGTime = $FileUpdate{"$base/spambox.cfgspamboxCfg"} = ftime("$base/spambox.cfg");
    }
    $Config{AutoReloadCfg} = $AutoReloadCfg = $new;
    return '';
}
