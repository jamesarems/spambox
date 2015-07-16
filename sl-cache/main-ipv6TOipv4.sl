#line 1 "sub main::ipv6TOipv4"
package main; sub ipv6TOipv4 {
    my $ip = shift;
    $ip =~ s/^.*?($IPv4Re)$/$1/o;
    return $ip;
}
