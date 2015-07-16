#line 1 "sub main::ConfigChangeMailPort2"
package main; sub ConfigChangeMailPort2 {my ($name, $old, $new, $init)=@_;
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
    $Config{listenPort2}=$listenPort2=$new;
    if($> == 0 || $highport || $^O eq "MSWin32") {

        # change the listenport2
        foreach my $lsn2 (@lsn2 ) {
            unpoll($lsn2,$readable);
            unpoll($lsn2,$writable);
            close($lsn2);
            delete $SocketCalls{$lsn2};
        }
        my ($lsn2,$lsn2I) = newListen($listenPort2,\&ConToThread,1);
        @lsn2 = @$lsn2; @lsn2I = @$lsn2I;
        for (@$lsn2I) {s/:::/\[::\]:/o;}
        mlog(0,"AdminUpdate: listening on new secondary mail port @$lsn2I (changed from $old)");
        return '';
    } else {

        # don't have permissions to change
        mlog(0,"AdminUpdate: request to listen on new secondary mail port $new (changed from $old) -- restart required; euid=$>");
        return "<br />Restart required; euid=$><script type=\"text/javascript\">alert(\'new secondary mail port - ASSP-Restart required\');</script>";
    }
}
