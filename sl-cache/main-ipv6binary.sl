#line 1 "sub main::ipv6binary"
package main; sub ipv6binary {
    my ($ip, $bits) = @_;
    return pack("a$bits", unpack 'B128', pack 'n8', map{my $t = hex($_);$t;} split(/:/o, ipv6expand($ip)));
}
