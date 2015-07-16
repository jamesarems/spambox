#line 1 "sub main::getDNSResolverSingle"
package main; sub getDNSResolverSingle {
    ThreadYield();
    my $class = shift;
    $class ||= 'Net::DNS::Resolver';
    my $resolver = $orgNewDNSResolver->($class,
        tcp_timeout => $DNStimeout,
        udp_timeout => $DNStimeout,
        udppacketsize => 2048,
        retrans     => $DNSretrans,
        retry       => $DNSretry,
        usevc       => 0,
        debug       => ($DebugSPF ? 1 : 0),
        @_
    );
    getRes('force', $resolver);
    return $resolver;
}
