#line 1 "sub ASSP::Whois::IP::whoisip_get_connect"
package ASSP::Whois::IP; sub whoisip_get_connect {
    my $whois_registrar = shift;
    my $s;
    my $c;
    require IO::Socket::INET6 if $main::CanUseIOSocketINET6;
    # round robin for the ARIN servers
    if ($whois_registrar eq 'whois.arin.net' && ($s = scalar @main::ARINservers) ) {
        $c = ++$main::ARINcounter;
        $whois_registrar = $main::ARINservers[($c % $s)];
        if ($whois_registrar) {
            &main::mlog(0,"info: try IP '$whois_registrar' for 'whois.arin.net'") if $main::DebugSPF || $main::SenderBaseLog >= 2;
        } else {
            $whois_registrar = 'whois.arin.net';
        }
    }

    my $sock = $main::CanUseIOSocketINET6
                ? IO::Socket::INET6->new(Proto=>'tcp',
                                         PeerAddr=>$whois_registrar,
                                         PeerPort=>'43',
                                         Timeout=>$Timeout,
                                         &main::getDestSockDom($whois_registrar),
                                         &main::getLocalAddress('DNS',$whois_registrar))
                : IO::Socket::INET->new( Proto=>'tcp',
                                         PeerAddr=>$whois_registrar,
                                         PeerPort=>'43',
                                         Timeout=>$Timeout,
                                         &main::getLocalAddress('DNS',$whois_registrar));

    unless($sock) {
    	&main::mlog(0,"warning: Failed to Connect to $whois_registrar at port 43 - $!");
        if ($c) {
            $c++;
            $whois_registrar = $main::ARINservers[($c % $s)];
            if ($whois_registrar) {
                &main::mlog(0,"info: try IP '$whois_registrar' for 'whois.arin.net'") if $main::DebugSPF || $main::SenderBaseLog >= 2;
            } else {
                $whois_registrar = 'whois.arin.net';
            }
        } else {
            sleep 1;
        }
        $sock = $main::CanUseIOSocketINET6
                ? IO::Socket::INET6->new(Proto=>'tcp',
                                         PeerAddr=>$whois_registrar,
                                         PeerPort=>'43',
                                         Timeout=>$Timeout,
                                         &main::getDestSockDom($whois_registrar),
                                         &main::getLocalAddress('DNS',$whois_registrar))
                : IO::Socket::INET->new( Proto=>'tcp',
                                         PeerAddr=>$whois_registrar,
                                         PeerPort=>'43',
                                         Timeout=>$Timeout),
                                         &main::getLocalAddress('DNS',$whois_registrar);
    	unless($sock) {
    	    &main::mlog(0,"warning: (retry) Failed to Connect to $whois_registrar at port 43 - $!");
            return;
    	}
    }
    $sock->blocking(0);
    return($sock);
}
