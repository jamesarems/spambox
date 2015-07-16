#line 1 "sub main::ConfigChangeSyncFile"
package main; sub ConfigChangeSyncFile {my ($name, $old, $new, $init)=@_;
    my $tnew;
    $tnew = checkOptionList($new,'syncConfigFile',$init) if $WorkerNumber == 0 or $WorkerNumber == 10000;
    if ($tnew =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$tnew);
    }
    return '<span class="negative"></span>' if $WorkerNumber != 0;
    $Config{$name} = ${$name} = $new unless $WorkerNumber;
    mlog(0,"AdminUpdate: $name changed from $old to $new") if $new ne $old && $WorkerName ne 'startup';
    $NextSyncConfig = time - 1;
    %subOIDLastLoad = ();
    if (&syncLoadConfigFile()) {
        return '';
    } else {
        return "<span class=\"positive\">updated - but sync-config-file was still not loaded - sync config is still incomplete</span>";
    }
}
