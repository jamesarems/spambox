#line 1 "sub main::downloadVersionFile"
package main; sub downloadVersionFile {
    d('downloadVersionFile-start');
    my $force;
    $force = 1 if ($NextSPAMBOXFileDownload == -1 or $NextVersionFileDownload == -1);
    &UpdateDownloadURLs();
    if (! $versionURL) {
        mlog(0,"warning: versionupdate: no download URL found for version.txt - skip update for 24 hours");
        $NextSPAMBOXFileDownload = time + 3600 * 24;
        $NextVersionFileDownload = time + 3600 * 24;
        return 0;
    }
    my $ret;
    my $file = "$base/version.txt";
    $ret = downloadHTTP("$versionURL",
                 $file,
                 \$NextVersionFileDownload,
                 "assp version check",16,12,4,4) if $file;
    if ($ret) {
        &UpdateDownloadURLs();
        downloadHTTP("$ChangeLogURL",
                     "$base/docs/changelog.txt",
                     0,
                     "assp change log",16,12,4,4);
    }
    if (open my $VS ,'<' ,"$file") {
        while (<$VS>) {
            s/\n|\r//og;
            s/^\s+//o;
            s/\s+$//o;
            next if /^\s*[#;]/o;
            next unless $_;
            if (/^\s*(\d+\.\d+\.\d+.+)$/o) {
                $availversion = $1;
                my $avv = "$availversion";
                my $stv = "$version$modversion";
                $avv =~ s/RC/\./gio;
                $stv =~ s/RC/\./gio;
                $avv =~ s/\s|\(|\)//gio;
                $stv =~ s/\s|\(|\)//gio;
                $stv = 0 if ($avv =~ /\d{5}(?:\.\d{1,2})?$/o && $stv =~ /(?:\.\d{1,2}){3}$/o);
                if ($avv gt $stv) {
                    mlog(0,"Info: new assp version $availversion is available for download at $NewAsspURL");
                    $ret = 1;
                } else {
                    $ret = 0;
                }
            }
            if (/^\s*versionURL\s*:\s*(http(?:s)?:\/\/.+)$/io) {
                $versionURL = $1;
            }
            if (/^\s*NewAsspURL\s*:\s*(http(?:s)?:\/\/.+)$/io) {
                $NewAsspURL = $1;
            }
        }
        close $VS;
    } else {
        $ret = 0;
    }
    return $ret || $force;
}
