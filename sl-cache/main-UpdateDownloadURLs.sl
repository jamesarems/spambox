#line 1 "sub main::UpdateDownloadURLs"
package main; sub UpdateDownloadURLs {
    if (open my $UVS , '<',"$base/version.txt") {
        while (<$UVS>) {
            s/\n|\r//go;
            s/^\s+//o;
            s/\s+$//o;
            next if /^\s*[#;]/o;
            next unless $_;
            if (/^\s*versionURL\s*:\s*(http(?:s)?:\/\/.+)$/io) {
                my $old = $versionURL;
                $versionURL = $1;
                mlog(0,"adminupdate: version.txt file download URL changed from $old to $versionURL") if $versionURL ne $old;
                next;
            }
            if (/^\s*NewAsspURL\s*:\s*(http(?:s)?:\/\/.+)$/io) {
                my $old = $NewAsspURL;
                $NewAsspURL = $1;
                mlog(0,"adminupdate: ASSP file download URL changed from $old to $NewAsspURL") if $NewAsspURL ne $old;
                next;
            }
            if (/^\s*ChangeLogURL\s*:\s*(http(?:s)?:\/\/.+)$/io) {
                my $old = $ChangeLogURL;
                $ChangeLogURL = $1;
                mlog(0,"adminupdate: ASSP changelog download URL changed from $old to $ChangeLogURL") if $ChangeLogURL ne $old;
                next;
            }
            if (/^\s*(\w+)\s*:\s*(.+)$/io) {
                my ($var,$val) = ($1,$2);
                next unless defined ${$var};
                $val =~ s/\s+$//o;
                my $old = ${$var};
                ${$var} = $val;
                if (exists $Config{$var}) {
                    $Config{$var} = $val;
                    $ConfigChanged = 1;
                    mlog(0,"adminupdate: version file changed $var from $old to $val") if $val ne $old;
                }
                next;
            }
        }
        close $UVS;
    }
}
