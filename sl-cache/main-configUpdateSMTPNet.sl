#line 1 "sub main::configUpdateSMTPNet"
package main; sub configUpdateSMTPNet {
    my ($name, $old, $new, $init)=@_;
    my $isproxy = scalar(keys %ProxySocket) ? ' and Proxy':'';
    mlog(0,"AdminUpdate: $name updated from '$old' to '$new'") unless $init || $new eq $old;
    mlog(0,"warning : $name is switch on - SMTP$isproxy listeners will be switched off") if ($init && $$name);
    return '' if ($new eq $old or $init);
    $$name = $new;
    $Config{$name} = $new;
    if ($new) {
        mlog(0,"warning : $name is switch on - SMTP$isproxy listeners will be switched off");
        foreach my $lsn (@lsn ) {
            unpoll($lsn,$readable) if $lsn;
            unpoll($lsn,$writable) if $lsn;
            eval{close($lsn);} if $lsn;
            delete $SocketCalls{$lsn} if $lsn;
        }

        foreach my $lsn (@lsn2 ) {
            unpoll($lsn,$readable) if $lsn;
            unpoll($lsn,$writable) if $lsn;
            eval{close($lsn);} if $lsn;
            delete $SocketCalls{$lsn} if $lsn;
        }

        foreach my $lsn (@lsnSSL ) {
            unpoll($lsn,$readable) if $lsn;
            unpoll($lsn,$writable) if $lsn;
            eval{close($lsn);} if $lsn;
            delete $SocketCalls{$lsn} if $lsn;
        }
        
        foreach my $lsn (@lsnRelay ) {
            unpoll($lsn,$readable) if $lsn;
            unpoll($lsn,$writable) if $lsn;
            eval{close($lsn);} if $lsn;
            delete $SocketCalls{$lsn} if $lsn;
        }

        while (my ($k,$v) = each(%Proxy)) {
            unpoll($ProxySocket{$k},$readable);
            unpoll($ProxySocket{$k},$writable);
            eval{close($ProxySocket{$k});};
            delete $SocketCalls{$ProxySocket{$k}};
        }
        %ProxySocket = ();
    } else {
        mlog(0,"info : $name is switch off - SMTP$isproxy listeners will be switched on");

        my ($lsn,$lsnI) = newListen($listenPort,\&ConToThread,1);
        @lsn = @$lsn; @lsnI = @$lsnI;
        mlog(0,"listening for SMTP connections on @lsnI") if @lsn;

        if($listenPortSSL && $CanUseIOSocketSSL) {
          my ($lsnSSL,$lsnSSLI) = newListenSSL($listenPortSSL,\&ConToThread,1);
          @lsnSSL = @$lsnSSL; @lsnSSLI = @$lsnSSLI;
          mlog(0,"listening for additional SMTP connections on @lsnSSLI") if @lsnSSL;
        }

        if($listenPort2) {
          my ($lsn2,$lsn2I) = newListen($listenPort2,\&ConToThread,1);
          @lsn2 = @$lsn2; @lsn2I = @$lsn2I;
          mlog(0,"listening for additional SMTP connections on @lsn2I") if @lsn2;
        }

        if($relayHost && $relayPort) {
          my ($lsnRelay,$lsnRelayI)=newListen($relayPort,\&ConToThread,1);
          @lsnRelay = @$lsnRelay; @lsnRelayI = @$lsnRelayI;
          mlog(0,"listening for SMTP relay connections on @lsnRelayI") if @lsnRelay;
        }

         while ((my $k,my $v) = each(%Proxy)) {
             my ($to,$allow) = split(/<=/o, $v);
             $allow = " allowed for $allow" if ($allow);
             my (@ProxySocket,@dummy) = newListen($k,\&ConToThread,2);
             $ProxySocket{$k} = shift @ProxySocket;
             mlog(0,"proxy started: listening on $k forwarded to $to$allow") if $ProxySocket{$k};
        }
    }
    return '';
}
