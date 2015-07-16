#line 1 "sub main::newListenSSL"
package main; sub newListenSSL {
    my($port,$handler,$threadhandler)=@_;
    my @s;
    my @sinfo;
    return \@s,\@sinfo if($DisableSMTPNetworking and $handler eq \&ConToThread);
    my $isWebListen = $handler eq \&NewWebConnection;
    my $isStatListen = $handler eq \&NewStatConnection;
    my $isSMTPListen = $handler eq \&ConToThread;
    $IO::Socket::SSL::DEBUG = $SSLDEBUG;
    foreach my $portA (split(/\|/o, $port)) {
        if($portA !~ /$HostRe?:?$PortRe/o) {
            mlog(0,"wrong (host) + port definition in '$portA' -- entry will be ignored !");
            next;
        }
        my @stt;
        my ($interface,$p)=$portA=~/($HostRe):($PortRe)/o;

        my %parms = getSSLParms(1);
        if ($interface) {
            $parms{LocalPort} = $p;
            $parms{LocalAddr} = $interface;
        } else {
            $parms{LocalPort} = $portA;
        }
        $parms{Listen} = 10;
        $parms{Reuse} = 1;
        $parms{SSL_startHandshake} = 1;
        if ($isWebListen) {
            if ($webSSLRequireCientCert) {
                $parms{SSL_verify_mode} = eval('SSL_VERIFY_PEER | SSL_VERIFY_FAIL_IF_NO_PEER_CERT | SSL_VERIFY_CLIENT_ONCE');
                $parms{SSL_verify_callback} = \&SSLWEBCertVerify if $SSLWEBCertVerifyCB;
            }
            if ($SSLWEBConfigure) {
                eval{$SSLWEBConfigure->(\%parms)};
                mlog(0,"error: SSLWEBConfigure - $SSLWEBConfigure call failed - $@") if $@;
            }
        }
        if ($isStatListen) {
            if ($statSSLRequireClientCert) {
                $parms{SSL_verify_mode} = eval('SSL_VERIFY_PEER | SSL_VERIFY_FAIL_IF_NO_PEER_CERT | SSL_VERIFY_CLIENT_ONCE');
                $parms{SSL_verify_callback} = \&SSLSTATCertVerify if $SSLSTATCertVerifyCB;
            }
            if ($SSLSTATConfigure) {
                eval{$SSLSTATConfigure->(\%parms)};
                mlog(0,"error: SSLSTATConfigure - $SSLSTATConfigure call failed - $@") if $@;
            }
        }
        if ($isSMTPListen) {
            if ($smtpSSLRequireClientCert) {
                $parms{SSL_verify_mode} = eval('SSL_VERIFY_PEER | SSL_VERIFY_FAIL_IF_NO_PEER_CERT | SSL_VERIFY_CLIENT_ONCE');
                $parms{SSL_verify_callback} = \&SSLSMTPCertVerify if $SSLSMTPCertVerifyCB;
            }
            if ($SSLSMTPConfigure) {
                eval{$SSLSMTPConfigure->(\%parms)};
                mlog(0,"error: SSLSMTPConfigure - $SSLSMTPConfigure call failed - $@") if $@;
            }
        }

        if ($CanUseIOSocketINET6) {
            my $isv4 = [&getDestSockDom($interface)]->[1] != AF_INET6;
            my ($s4,$s6);
            if (! $interface || $isv4) {
                $parms{Domain} = AF_INET;
                $parms{LocalAddr} ||= '0.0.0.0';
                if ($s4 = IO::Socket::SSL->new(%parms)) {
                    push @stt,$s4;
                } else {
                    mlog(0,"error: unable to create IPv4 socket to $parms{LocalAddr}:$parms{LocalPort} - ".IO::Socket::SSL::errstr());
                }
                delete $parms{LocalAddr} if ! $interface;
            }
            if (! $interface || ! $isv4) {
                $parms{Domain} = AF_INET6;
                $parms{LocalAddr} ||= '[::]';
                if ($s6 = IO::Socket::SSL->new(%parms)) {
                    push @stt,$s6;
                } else {
                    mlog(0,"error: unable to create IPv6 socket to $parms{LocalAddr}:$parms{LocalPort} - ".IO::Socket::SSL::errstr());
                }
            }
        } else {
            $parms{Domain} = AF_INET;
            $parms{LocalAddr} ||= '0.0.0.0';
            my $s4;
            if ($s4 = IO::Socket::SSL->new(%parms)) {
                push @stt,$s4;
            } else {
                mlog(0,"error: unable to create IPv4 socket to $parms{LocalAddr}:$parms{LocalPort} - ".IO::Socket::SSL::errstr());
            }
        }

        if ($SSLDEBUG > 1) {
            while(my($k,$v)=each(%parms)) {
                print "ssl-new-listener: $k = $v\n";
            }
        }

        if(! @stt) {
            mlog(0,"error: couldn't create server SSL-socket on port '$portA' -- maybe another service is running or I'm not root (uid=$>)? - or a wrong IP address is specified?");
            next;
        }

        foreach my $s (@stt) {
            $SocketCalls{$s}=$handler;
            $ThreadHandler{$s} = $threadhandler if $threadhandler;    # tell thread what to do
            &dopoll($s,$readable,POLLIN);
            push @s,$s;
            push @sinfo,$s->sockhost . ':' . $s->sockport;
        }
    }
    return \@s,\@sinfo;
}
