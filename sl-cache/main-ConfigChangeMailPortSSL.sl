#line 1 "sub main::ConfigChangeMailPortSSL"
package main; sub ConfigChangeMailPortSSL {
    my ( $name, $old, $new , $init) = @_;
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
    $Config{listenPortSSL}=$listenPortSSL = $new;
    if($> == 0 || $highport || $^O eq "MSWin32") {

        # change the listenportSSL
        foreach my $lfh (@lsnSSL) {
            unpoll($lfh,$readable,POLLIN);
            unpoll($lfh,$writable,POLLIN);
            delete $SocketCalls{$lfh};
            close($lfh);
        }
        if ($CanUseIOSocketSSL) {
            my ($lsnSSL,$lsnSSLI) = newListenSSL($listenPortSSL,\&ConToThread,1);
            @lsnSSL = @$lsnSSL; @lsnSSLI = @$lsnSSLI;
            for (@$lsnSSLI) {s/:::/\[::\]:/o;}
            mlog( 0,"AdminUpdate: listening on new SSL mail port @$lsnSSLI (changed from '$old')");
        } else {
            mlog( 0,"AdminUpdate: new SSL mail port '$listenPortSSL' (changed from '$old')");
        }
        return '';
    } else {

        # don't have permissions to change
        mlog( 0,
"AdminUpdate: request to listen on new SSL mail port '$new' (changed from '$old') -- restart required; euid=$>"
        );
        return "<br />Restart required; euid=$>";
    }
}
