#line 1 "sub main::fileIncUpdated"
package main; sub fileIncUpdated {
    my ( $fil, $configname ) = @_;
    return 0 unless exists $FileIncUpdate{"$fil$configname"};

    my $changed = 0;
    foreach my $f (keys %{$FileIncUpdate{"$fil$configname"}}) {
        my ($old, $new) = ($FileIncUpdate{"$fil$configname"}{$f} , ftime($f));
        $old = $FileIncUpdate{"$fil$configname"}{$f} = $new if (abs($old - $new) == 3600);   # DST hack
        next if $old == $new;
        $old = $old ? timestring($old) : 'n/a';
        $new = $new ? timestring($new) : 'n/a';
        mlog(0,"info: found changed include file '$f' for config '$configname' - old ($old), new ($new)") if $MaintenanceLog > 1 && $WorkerNumber == 10000;
        mlog(0,"adminupdate: include file '$f' for config '$configname' was changed") if ($WorkerNumber == 0 && ($configname ne 'Groups' || ($configname eq 'Groups' && ($WebIP{$ActWebSess}->{user} || $syncUser))));
        $changed = 1;
    }
    return $changed;
}
