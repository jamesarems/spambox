#line 1 "sub main::ConfigChangeStatPort"
package main; sub ConfigChangeStatPort {my ($name, $old, $new, $init)=@_;
    my $usessl;
    my @dummy;
    my $highport = 1;
    return if $new eq $old && ! $init;
    return if $WorkerNumber != 0;
    my $dummy;
    my $StatSocket;
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
    $webStatPort=$Config{webStatPort}=$new;
    if($> == 0 || $highport || $^O eq "MSWin32") {

        # change the listenport
        foreach my $StatSock (@StatSocket) {
            unpoll($StatSock,$readable);
            unpoll($StatSock,$writable);
            close($StatSock) || eval{$StatSock->close;} || eval{$StatSock->kill_socket();} ||
            delete $SocketCalls{$StatSock};
        }

        if ($CanUseIOSocketSSL && $enableWebStatSSL) {
            ($StatSocket,$dummy) = newListenSSL($webStatPort,\&NewStatConnection);
            @StatSocket = @$StatSocket;
            $usessl = 'HTTPS';
        } else {
            ($StatSocket,$dummy) = newListen($webStatPort,\&NewStatConnection);
            @StatSocket = @$StatSocket;
            $usessl = '';
        }
        for (@$dummy) {s/:::/\[::\]:/o;}
        if(@StatSocket) {
            mlog(0,"AdminUpdate: listening on new stat port @$dummy $usessl (changed from $old)");
        } else {

            # couldn't open the port -- switch back
            if ($usessl && $new eq $old) {
                ($StatSocket,$dummy) = newListen($webStatPort,\&NewStatConnection);
                @StatSocket = @$StatSocket;
            } elsif ($usessl) {
                ($StatSocket,$dummy) = newListenSSL($webStatPort,\&NewStatConnection);
                @StatSocket = @$StatSocket;
            } else {
                ($StatSocket,$dummy) = newListen($webStatPort,\&NewStatConnection);
                @StatSocket = @$StatSocket;
            }
            for (@$dummy) {s/:::/\[::\]:/o;}
            mlog(0,"AdminUpdate: couldn't open new port -- still listening on @$dummy");
            $webStatPort=$Config{$name}=$old;
            return "<span class=\"negative\">Couldn't open new port $new -- still listening on @$dummy</span>";
        }
        return '';
    } else {

        # don't have permissions to change
        mlog(0,"AdminUpdate: request to listen on new stat port $new $usessl (changed from $old) -- restart required; euid=$>");
        return "<br />Restart required; euid=$><script type=\"text/javascript\">alert(\'new stat port $usessl - ASSP-Restart required\');</script>";
    }
}
