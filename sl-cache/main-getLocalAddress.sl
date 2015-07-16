#line 1 "sub main::getLocalAddress"
package main; sub getLocalAddress {
    my ($hash, $destination) = @_;
    d("getLocalAddress - $hash , $destination");

    my $h = $hash;
    my $key = ($h eq 'LDAP') ? 'localaddr' : 'LocalAddr';
    $hash = \%{'main::'.$hash.'_local_address'};
    return unless scalar keys %{$hash};   # nothing defined
    $destination =~ s/^($HostRe):$PortRe$/$1/o;
    return if $destination =~ /^\d+$/o;  # is a port only
    if (! ($destination =~ s/^\[?($IPRe)\]?$/$1/o)) {    # a hostname was given - resolve it
        if (exists $hash->{$destination}) {
            mlog(0,"info: use local IP address '$hash->{$destination}' for found $h target '$destination'") if $ConnectionLog >= 2;
            return (wantarray ? ($key,$hash->{$destination}) : $hash->{$destination});
        }
        my $m1 = matchHashKey($hash,$destination,'0 1 1');
        if ($m1) {
            mlog(0,"info: use local IP address '$m1' for matched $h target '$destination'") if $ConnectionLog >= 2;
            return (wantarray ? ($key,$m1) : $m1);
        }
        my (@res,$ip4,$ip6,$port);
        if ($CanUseIOSocketINET6) {
            eval(<<EOT);
                @res = Socket6::getaddrinfo($destination,25,AF_INET6);
	            ($ip6, $port) = getnameinfo($res[3], NI_NUMERICHOST | NI_NUMERICSERV) if $res[3];
EOT
            eval(<<EOT)  if $@ || !($ip6 =~ s/^\[?($IPv6Re)\]?$/$1/o);
                $ip6 = Socket6::inet_ntop( AF_INET6, scalar( Socket6::gethostbyname2($destination,AF_INET6) ) );
EOT
            $ip6 = undef if $@ || !($ip6 =~ s/^\[?($IPv6Re)\]?$/$1/o);
        }
        if (! $ip6) {
            eval{$ip4 = inet_ntoa( scalar( gethostbyname($destination) ) );};
            $ip4 = undef if ($ip4 !~ /^$IPv4Re$/o);
        }
        $destination = $ip6 || $ip4;
    }
    return unless $destination;
    my $lip = matchHashKey($hash,$destination,'0 1 1');
    if ($lip) {
        mlog(0,"info: use local IP address '$lip' for matched $h target '$destination'") if $ConnectionLog >= 2;
        return (wantarray ? ($key,$lip) : $lip);
    }
    return;
}
