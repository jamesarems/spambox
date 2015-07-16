#line 1 "sub main::ConfigChangeAutoUpdate"
package main; sub ConfigChangeAutoUpdate {
    my ($name, $old, $new, $init)=@_;
    return if $WorkerNumber != 0;
    mlog(0,"AdminUpdate: $name from '$old' to '$new'") unless $init || $new eq $old;
    $$name = $Config{$name} = $new;
    my $ret = '';
    if ($new == 2 && $new ne $old && ! $init) {
        mlog(0,"info: forced to run a low priority autoupdate now") if $MaintenanceLog;
        $ret = '* forced to run a low priority autoupdate now';
        open(my $F ,'>>',"$base/version.txt");
        close $F;
        mlog(0,"info: changed file time of file $base/version.txt") if $MaintenanceLog >= 2;
        unlink "$base/download/spambox.pl.gz.old";
        move("$base/download/spambox.pl.gz","$base/download/spambox.pl.gz.old");
        mlog(0,"info: moved file $base/download/spambox.pl.gz to $base/download/spambox.pl.gz.old") if $MaintenanceLog >= 2;
        $NextSPAMBOXFileDownload = -1;
        $NextVersionFileDownload = -1;
    }
    return $ret;
}
