#line 1 "sub main::getNameserver"
package main; sub getNameserver {
    my @nameservers = scalar(@_) ? @_ : @nameservers;
    my @ns;
    for (@nameservers) {
        next unless $_;
        push @ns, $_;
    }
    return @ns unless $DNSServerLimit;
    return @ns if (scalar(@ns) <= $DNSServerLimit);
    return @ns[0..($DNSServerLimit - 1)];
}
