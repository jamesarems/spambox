#line 1 "sub main::getDestSockDom"
package main; sub getDestSockDom {
    my $dest = shift;
    return unless $dest;
    my $orgdest = $dest;
    my ($ip4,$ip6,$ip,%Domain);
    $ip = $1 if $dest =~ /^\[?($IPRe)\]?/o;
    if (! $ip) {
        my ($port,@res);
        $dest =~ s/^\[//o;
        $dest =~ s/\]?:\d+$//o;
        if ($CanUseIOSocketINET6) {
            eval(<<EOT);
                @res = Socket6::getaddrinfo($dest,25,AF_INET6);
	            ($ip6, $port) = getnameinfo($res[3], NI_NUMERICHOST | NI_NUMERICSERV) if $res[3];
EOT
            eval(<<EOT)  if $@ || !($ip6 =~ s/^\[?($IPv6Re)\]?$/$1/o);
                $ip6 = Socket6::inet_ntop( AF_INET6, scalar( Socket6::gethostbyname2($dest,AF_INET6) ) );
EOT
            $ip6 = undef if $@ || !($ip6 =~ s/^\[?($IPv6Re)\]?$/$1/o);
            mlog(0,"info: resolved IPv6 $ip6 for hostname $dest") if $ip6 && $ConnectionLog >= 2;
        }
        if (! $ip6) {
            eval{$ip4 = inet_ntoa( scalar( gethostbyname($dest) ) );};
            $ip4 = undef if ($ip4 !~ /^$IPv4Re$/o);
            mlog(0,"info: resolved IPv4 $ip4 for hostname $dest") if $ip4 && $ConnectionLog >= 2;
        }
    } else {
        $ip6 = $1 if $ip =~/^\[?($IPv6Re)\]?$/o;
        $ip4 = $1 if ! $ip6 && $ip =~/^($IPv4Re)$/o;
    }
    if ($ip6) {
        $Domain{Domain} = AF_INET6;
    } elsif ($ip4) {
        $Domain{Domain} = AF_INET;
    } else {
        $Domain{Domain} = AF_UNSPEC;
        mlog(0,"error: found unresolvable ($dest) - hostname or suspicious IP address definition in $orgdest");
    }
    return %Domain;
}
