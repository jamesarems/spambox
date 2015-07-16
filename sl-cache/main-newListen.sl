#line 1 "sub main::newListen"
package main; sub newListen {
    my($port,$handler,$threadhandler)=@_;
    my @s;
    my @sinfo;
    return \@s,\@sinfo if($DisableSMTPNetworking and $handler eq \&ConToThread);
    foreach my $portA (split(/\|/o, $port)) {
        if($portA !~ /$HostRe?:?$PortRe/o) {
            mlog(0,"wrong (host) + port definition in '$portA' -- entry will be ignored !");
            next;
        }
        my @stt;
        my ($interface,$p)=$portA=~/($HostRe):($PortRe)/o;

        my %parms = $interface
                    ? ('LocalPort' => $p, 'LocalAddr' => $interface)
                    : ('LocalPort' => $portA);
        $parms{Listen} = 10;
        $parms{Reuse} = 1;
        
        if ($CanUseIOSocketINET6) {
            my $isv4 = [&getDestSockDom($interface)]->[1] != AF_INET6;
            my ($s4,$s6);
            if (! $interface || $isv4) {
                $parms{Domain} = AF_INET;
                $parms{LocalAddr} ||= '0.0.0.0';
                $s4 = IO::Socket::INET6->new(%parms);
                push @stt,$s4 if $s4;
                delete $parms{LocalAddr} if ! $interface;
            }
            if (! $interface || ! $isv4) {
                $parms{Domain} = AF_INET6;
                $parms{LocalAddr} ||= '[::]';
                $s6 = IO::Socket::INET6->new(%parms);
                push @stt,$s6 if $s6;
            }
        } else {
            $parms{Domain} = AF_INET;
            $parms{LocalAddr} ||= '0.0.0.0';
            my $s4 = IO::Socket::INET->new(%parms);
            push @stt,$s4 if $s4;
        }
        if(! @stt) {
            mlog(0,"error: couldn't create server socket on port '$portA' -- maybe another service is running or I'm not root (uid=$>)? -- or a wrong IP address is defined? -- $!");
            next;
        }
        foreach my $s (@stt) {
            $s->blocking(0);
            $SocketCalls{$s}=$handler;
            $ThreadHandler{$s} = $threadhandler if $threadhandler;    # tell thread what to do
            &dopoll($s,$readable,POLLIN);
            push @s,$s;
            push @sinfo,$s->sockhost . ':' . $s->sockport;
        }
    }
    return \@s,\@sinfo;
}
