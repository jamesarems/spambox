#line 1 "sub main::threadCheckConfig"
package main; sub threadCheckConfig {
    my $CFG;
    my $ok = 1;
    open($CFG,'<',"$base/spambox.cfg") or (mlog(0,"warning: can't read $base/spambox.cfg") && return);
    my $enc = ASSP::CRYPT->new($Config{webAdminPassword},0);
    while (<$CFG>) {
        s/\r|\n//go;
        s/^$UTFBOMRE//o;
        my ($k,$v) = split(/:=/o,$_,2);
        next unless $k;
        next unless exists $Config{$k};
        next if $k eq 'DataBaseDebug';
        next if $k eq 'silent';
        next if (exists $cryptConfigVars{$k});
        if (! is_shared($$k)) {
            mlog(0,"error: the config variable '$k' is not shared in this thread");
            $ok = 0;
        }
        if ($v ne $Config{$k}) {
            mlog(0,"error: the value of config variable '$k' -> ('$v') in spambox.cfg differs from the config hash ('$Config{$k}') in this thread");
            $ok = 0;
        }
        if ($v ne $$k) {
            mlog(0,"error: the value of config variable '$k' -> ('$v') in spambox.cfg differs from the config variable ('$$k') in this thread");
            $ok = 0;
        }
    }
    if ( $ok && $MaintenanceLog >=2 ) {
        mlog(0,"info: the configuration in this thread was checked - OK");
    } elsif (! $ok) {
        mlog(0,"error: the configuration in this thread is wrong - check your perl installation");
    }
    close $CFG;
}
