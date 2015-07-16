#line 1 "sub main::POP3Collect"
package main; sub POP3Collect {
    return 0 unless $allowPOP3;
    return 0 unless $POP3Interval;
    return 0 unless -e "$base/spambox_pop3.pl";

    return 0 if $POP3ConfigFile !~ /^ *file: *.+/io;
    d('POP3 - collect');

    my $perl = $perl;
    my $cmd = "\"$perl\" \"$base/spambox_pop3.pl\" \"$base\" 2>&1";
    $cmd =~ s/\//\\/go if $^O eq "MSWin32";
    my $out = qx($cmd);

    foreach (split(/\n/o,$out)) {
        s/\r|\n//go;
        mlog(0,$_) if $MaintenanceLog;
    }
    return 1;
}
