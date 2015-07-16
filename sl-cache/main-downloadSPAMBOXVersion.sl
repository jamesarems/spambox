#line 1 "sub main::downloadSPAMBOXVersion"
package main; sub downloadSPAMBOXVersion {
    d('downloadSPAMBOXVersion-start');
    return 0 unless $AutoUpdateSPAMBOX;
    checkVersionAge();
    &UpdateDownloadURLs();
    if (! $NewAsspURL ) {
        mlog(0,"warning: autoupdate: no download URL found for spambox.pl - skip update for 24 hours");
        $NextSPAMBOXFileDownload = time + 3600 * 24;
        $NextVersionFileDownload = time + 3600 * 24;
        return 0;
    }
    if (! $versionURL) {
        mlog(0,"warning: autoupdate: no download URL found for version.txt - skip update for 24 hours");
        $NextSPAMBOXFileDownload = time + 3600 * 24;
        $NextVersionFileDownload = time + 3600 * 24;
        return 0;
    }
    my $assp = $assp;
    $assp =~ s/\\/\//go;
    $assp =~ s/\/\//\//go;
    $assp = $base.'/'.$assp if ($assp !~ /\Q$base\E/io);
    if (-e "$base/download/spambox.pl" && ! -w "$base/download/spambox.pl") {
        mlog(0,"warning: autoupdate: unable to write to $base/download/spambox.pl - skip update - please check the file permission");
        $NextSPAMBOXFileDownload = time + 3600;
        return 0;
    }
    if (-e "$base/download/spambox.pl.gz" && ! -w "$base/download/spambox.pl.gz") {
        mlog(0,"warning: autoupdate: unable to write to $base/download/spambox.pl.gz - skip update - please check the file permission");
        $NextSPAMBOXFileDownload = time + 3600;
        return 0;
    }
    if (! -w "$assp") {
        mlog(0,"warning: autoupdate: unable to write to $assp - skip update - please check the file permission");
        $NextSPAMBOXFileDownload = time + 3600;
        return 0;
    }
    -d "$base/download" or mkdir "$base/download", 0755;
    if (! -e "$base/download/spambox.pl" && ! copy("$assp","$base/download/spambox.pl")) {
        mlog(0,"warning: autoupdate: unable to copy current script '$assp' to '$base/download/spambox.pl' - skip update - $!");
        $NextSPAMBOXFileDownload = time + 3600;
        return 0;
    }
    unless (&downloadVersionFile()){
        $NextSPAMBOXFileDownload = $NextVersionFileDownload;
        return 0;
    }
    my $ret;
    $NextSPAMBOXFileDownload = 0;
    mlog(0,"Info: autoupdate: performing spambox.pl.gz download to $base/download/spambox.pl.gz") if $MaintenanceLog;
    $ret = downloadHTTP("$NewAsspURL",
                 "$base/download/spambox.pl.gz",
                 \$NextSPAMBOXFileDownload,
                 "spambox.pl.gz",16,12,4,4);
    return 0 unless $ret;
    mlog(0,"Info: autoupdate: new spambox.pl.gz downloaded to $base/download/spambox.pl.gz") if $MaintenanceLog;
    if (unzipgz("$base/download/spambox.pl.gz", "$base/download/spambox.pl")) {
        mlog(0,"info: autoupdate: new assp version '$base/download/spambox.pl' available - version $availversion") if $MaintenanceLog;
    } else {
        mlog(0,"warning: autoupdate: unable to unzip '$base/download/spambox.pl.gz' to '$base/download/spambox.pl' - skip update");
        return 0;
    }
    mlog(0,"Info: saving current script '$assp' to 'assp_$version$modversion.pl'") if $MaintenanceLog;
    if (! copy("$assp","$base/download/assp_$version$modversion.pl")) {
        mlog(0,"warning: autoupdate: unable to save current script '$assp' to '$base/download/assp_$version$modversion.pl' - skip update - $!");
        return 0;
    }
    my $cmd;
    if ($^O eq "MSWin32") {
        $cmd = '"' . $perl . '"' . " -c \"$base/download/spambox.pl\" \"$base\" 2>&1";
    } else {
        $cmd = '\'' . $perl . '\'' . " -c \'$base/download/spambox.pl\' \'$base\' 2>&1";
    }
    my $res = qx($cmd);
    if ($res =~ /syntax\s+OK/igo) {
        mlog(0,"info: autoupdate: syntax check for '$base/download/spambox.pl' returned OK");
    } else {
        mlog(0,"warning: autoupdate: syntax error in '$base/download/spambox.pl' - skip spambox.pl update - syntax error is: $res");
        return 0;
    }
    if ($res =~ /assp\s+(.+)?is starting/io) {
        my $avv = $1;
        $avv =~ s/RC/\./gio;
        $avv =~ s/\s|\(|\)//gio;
        my $stv = "$version$modversion";
        $stv =~ s/RC/\./gio;
        $stv =~ s/\s|\(|\)//gio;
        my $upd = 0;
        $upd = 1 if ($avv =~ /\d{5}(?:\.\d{1,2})?$/o && $stv =~ /(?:\.\d{1,2}){3}$/o);
        $upd ||= ($stv lt $avv);
        if (! $upd) {
            mlog(0,"warning: autoupdate: version of downloaded '$base/download/spambox.pl' ($avv) is less or equal to the running version of assp ($stv) - skip spambox.pl update");
            return 0;
        }
    }
    return 0 if $AutoUpdateSPAMBOX == 1;
    if (copy("$base/download/spambox.pl", "$assp")) {
        mlog(0,"info: autoupdate: new version assp installed - '$assp' - version $availversion");
    } else {
        mlog(0,"warning: autoupdate: unable to replace current script '$assp' - skip update - $!");
        return 0;
    }
    return 1 if (lc $AutoRestartAfterCodeChange eq 'immed' &&
        ($AsAService || $AsADaemon || $AutoRestartCmd));
    $codeChanged = 1 if $AutoRestartAfterCodeChange;
    return 1;
}
