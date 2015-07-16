#line 1 "sub main::ConfigChangeMailPort"
package main; sub ConfigChangeMailPort {my ($name, $old, $new, $init)=@_;
    my $highport = 1;
    return if $new eq $old;
    foreach my $port (split(/\|/o,$new)) {
        if ($port =~ /^.+:([^:]+)$/o) {
            if ($1 < 1024) {
                $highport = 0;
                last;
            }
        } else {
            if ($port < 1024) {
                $highport = 0;
                last;
            }
        }
    }
    $Config{listenPort}=$listenPort=$new;
    if($> == 0 || $highport || $^O eq "MSWin32") {

        # change the listenport

        foreach my $lsn (@lsn ) {
            unpoll($lsn,$readable);
            unpoll($lsn,$writable);
            close($lsn);
            delete $SocketCalls{$lsn};
        }
        my ($lsn,$lsnI) = newListen($listenPort,\&ConToThread,1);
        @lsn = @$lsn; @lsnI = @$lsnI;
        for (@$lsnI) {s/:::/\[::\]:/o;}
        mlog(0,"AdminUpdate: listening on new mail port @$lsnI (changed from $old) ");
        return '';
    } else {

        # don't have permissions to change
        mlog(0,"AdminUpdate: request to listen on new mail port $new (changed from $old) -- restart required; euid=$>");
        return "<br />Restart required; euid=$><script type=\"text/javascript\">alert(\'new mail port - SPAMBOX-Restart required\');</script>";
    }
}
