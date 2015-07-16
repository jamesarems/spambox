#line 1 "sub main::SaveConfigSettings"
package main; sub SaveConfigSettings {
    return 0 if $Config{spamboxCfgVersion} eq $MAINVERSION;
    my $bak = $Config{spamboxCfgVersion};
    $bak =~ s/^([\d\.]+)\(([\d\.]+)\)/$1.$2/o;
    copy("$base/spambox.cfg","$base/spambox_$bak.cfg.bak") or
        mlog(0,"error: unable to backup '$base/spambox.cfg' to '$base/spambox_$bak.cfg.bak' after version change from '$Config{spamboxCfgVersion}' to '$MAINVERSION'");
    $spamboxCfgVersion = $Config{spamboxCfgVersion} = $MAINVERSION;
    SaveConfigSettingsForce();
    return 1;
}
