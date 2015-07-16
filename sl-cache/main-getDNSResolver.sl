#line 1 "sub main::getDNSResolver"
package main; sub getDNSResolver {
    ThreadYield();
    if (! $DNSReuseSocket || ! $DNSresolver || $DNSresolverTime{$WorkerNumber} < time ) {
        mlog(0,"info: new DNSresolver: reuse  $DNSReuseSocket, resolver $DNSresolver, resolver-time $DNSresolverTime{$WorkerNumber}, time ".time) if $DebugSPF;
        d("info: new DNSresolver: reuse  $DNSReuseSocket, resolver $DNSresolver, resolver-time $DNSresolverTime{$WorkerNumber}, time ".time,1);
        if ($DNSresolver) {
            my @sock;
            push @sock, $DNSresolver->{'sockets'}[AF_INET]{'UDP'} if defined $DNSresolver->{'sockets'}[AF_INET]{'UDP'};
            push @sock, $DNSresolver->{'sockets'}[AF_INET6()]{'UDP'} if defined $DNSresolver->{'sockets'}[AF_INET6()]{'UDP'};
            push @sock, values %{$DNSresolver->{'sockets'}[AF_UNSPEC]} if defined $DNSresolver->{'sockets'}[AF_UNSPEC];
            if (@sock) {
                mlog(0,"info: destroy old DNSresolver") if $DebugSPF;
                d("info: destroy old DNSresolver",1);
                DNSSocketsClose(@sock);
            }
            $DNSresolver = undef;
        }
        my $class = shift;
        my @nameservers = getNameserver();
        $class ||= 'Net::DNS::Resolver';
        $DNSresolver = $orgNewDNSResolver->($class,
            nameservers => \@nameservers,
            tcp_timeout => $DNStimeout,
            udp_timeout => $DNStimeout,
            udppacketsize => 2048,
            retrans     => $DNSretrans,
            retry       => $DNSretry,
            persistent_udp => $DNSReuseSocket,
            persistent_tcp => $DNSReuseSocket,
            usevc => 0,
            debug       =>  ($DebugSPF ? 1 : 0),
            @_,
            getLocalAddress('DNS',$nameservers[0])
        );
        getRes('force', $DNSresolver);
    } else {
        mlog(0,"info: reuse DNSresolver") if $DebugSPF;
        d("info: reuse DNSresolver",1);
        my @sock;
        push @sock, $DNSresolver->{'sockets'}[AF_INET]{'UDP'} if defined $DNSresolver->{'sockets'}[AF_INET]{'UDP'};
        push @sock, $DNSresolver->{'sockets'}[AF_INET6()]{'UDP'} if defined $DNSresolver->{'sockets'}[AF_INET6()]{'UDP'};
        push @sock, values %{$DNSresolver->{'sockets'}[AF_UNSPEC]} if defined $DNSresolver->{'sockets'}[AF_UNSPEC];
        if (@sock) {
            mlog(0,"info: cleanup reused DNSresolver") if $DebugSPF;
            d("info: cleanup reused DNSresolver",1);
            DNSSocketsCleanup(@sock);
        }
    }
    $DNSresolverTime{$WorkerNumber} = time + $DNSresolverLifeTime if $DNSresolver;
    return $DNSresolver;
}
