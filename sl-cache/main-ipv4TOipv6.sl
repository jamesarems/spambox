#line 1 "sub main::ipv4TOipv6"
package main; sub ipv4TOipv6 {
    my $ip = shift;
    $ip =~ s/0?x?([A-F][A-F0-9]?|[A-F0-9]?[A-F])/hex($1)/goie;
   
    my ($h1,$h2,$h3,$h4) = split(/\./o,$ip);
    return sprintf("%x",256 * $h1 + $h2).':'.sprintf("%x",256 * $h3 + $h4);
}
