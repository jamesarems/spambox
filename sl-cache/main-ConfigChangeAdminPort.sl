#line 1 "sub main::ConfigChangeAdminPort"
package main; sub ConfigChangeAdminPort {my ($name, $old, $new, $init)=@_;
    my $usessl;
    my $highport = 1;
    return if $new eq $old && ! $init;
    return if $WorkerNumber != 0;
    my $dummy;
    my $WebSocket;
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
    $webAdminPort=$Config{webAdminPort}=$new;
    if($> == 0 || $highport || $^O eq "MSWin32") {

        # change the listenport
        foreach my $WebSock (@WebSocket) {
            unpoll($WebSock,$readable);
            unpoll($WebSock,$writable);
            close($WebSock) || eval{$WebSock->close;} || eval{$WebSock->kill_socket();} ||
            mlog(0,"warning: unable to close WebSocket: $WebSocket");
            delete $SocketCalls{$WebSock};
        }
        
        if ($CanUseIOSocketSSL && $enableWebAdminSSL) {
            ($WebSocket,$dummy) = newListenSSL($webAdminPort,\&NewWebConnection);
            @WebSocket = @$WebSocket;
            $usessl = 'HTTPS';
        } else {
            ($WebSocket,$dummy) = newListen($webAdminPort,\&NewWebConnection);
            @WebSocket = @$WebSocket;
            $usessl = '';
        }
        for (@$dummy) {s/:::/\[::\]:/o;}
        if(@WebSocket) {
            mlog(0,"AdminUpdate: listening on new admin port @$dummy $usessl (changed from $old)");
        } else {

            # couldn't open the port -- switch back
            if ($usessl && $new eq $old) {
                ($WebSocket,$dummy) = newListen($webAdminPort,\&NewWebConnection);
                @WebSocket = @$WebSocket;
            } elsif ($usessl) {
                ($WebSocket,$dummy) = newListenSSL($webAdminPort,\&NewWebConnection);
                @WebSocket = @$WebSocket;
            } else {
                ($WebSocket,$dummy) = newListen($webAdminPort,\&NewWebConnection);
                @WebSocket = @$WebSocket;
            }
            for (@$dummy) {s/:::/\[::\]:/o;}
            mlog(0,"AdminUpdate: couldn't open new port -- still listening on @$dummy");
            $webAdminPort=$Config{$name}=$old;
            return "<span class=\"negative\">Couldn't open new port $new -- still listening on @$dummy</span>";
        }
        return '';
    } else {

        # don't have permissions to change
        mlog(0,"AdminUpdate: request to listen on new admin port $new $usessl (changed from $old) -- restart required; euid=$>");
        return "<br />Restart required; euid=$><script type=\"text/javascript\">alert(\'new admin port $usessl - SPAMBOX-Restart required\');</script>";
    }
}
