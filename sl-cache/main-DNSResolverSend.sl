#line 1 "sub main::DNSResolverSend"
package main; sub DNSResolverSend {
    my $self = shift;
    if ($DebugSPF) {
        my($package, $file, $line) = caller;
        mlog(0,"info: DNSResolverSend: caller: $package, $line, @_");
    }
    return $orgSendDNSResolver->($self,@_) unless $DNSReuseSocket;
    my @sock;
    push @sock, $self->{'sockets'}[AF_INET]{'UDP'} if defined $self->{'sockets'}[AF_INET]{'UDP'};
    push @sock, $self->{'sockets'}[AF_INET6()]{'UDP'} if defined $self->{'sockets'}[AF_INET6()]{'UDP'};
    push @sock, values %{$self->{'sockets'}[AF_UNSPEC]} if defined $self->{'sockets'}[AF_UNSPEC];
    if (@sock) {
        mlog(0,"info: DNSResolverSend: cleanup reused DNSresolver") if $DebugSPF;
        d("info: cleanup reused DNSresolver",1);
        DNSSocketsCleanup(@sock);
    }
    return $orgSendDNSResolver->($self,@_);
}
