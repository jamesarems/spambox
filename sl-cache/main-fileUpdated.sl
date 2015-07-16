#line 1 "sub main::fileUpdated"
package main; sub fileUpdated {

    my ( $fil, $configname ) = @_;

    $fil = "$base/$fil" if $fil !~ /^(?:(?:[a-z]:)?[\/\\]|\Q$base\E)/io;

    #$fil="$base/$fil" if $fil!~/^\Q$base\E/io;
    return 0 unless (-e $fil);
    return 1 unless $FileUpdate{"$fil$configname"};
    my ($old, $new) = ($FileUpdate{"$fil$configname"} , ftime($fil));
    $old = $FileUpdate{"$fil$configname"} = $new if (abs($old - $new) == 3600);  # DST hack
    if ($configname eq 'spamboxCode' && $old != $new && $spamboxCodeMD5 eq eval{getMD5File($fil);}) {
        $FileUpdate{"$fil$configname"} = $new;
        return 0;
    }
    if ($old != $new) {
        $old = $old ? timestring($old) : 'n/a';
        $new = $new ? timestring($new) : 'n/a';
        mlog(0,"info: found changed file '$fil' for config '$configname' - old ($old), new ($new)") if ($MaintenanceLog > 1 && $WorkerNumber == 10000);
        mlog(0,"adminupdate: file '$fil' for config '$configname' was changed") if ($WorkerNumber == 0 && ($configname ne 'Groups' || ($configname eq 'Groups' && ($WebIP{$ActWebSess}->{user} || $syncUser))));
        return 1;
    }
    return fileIncUpdated($fil,$configname);
}
