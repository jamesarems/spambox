#line 1 "sub main::ipv6expand"
package main; sub ipv6expand {
    my $ip = shift;
    return $ip if ($ip !~ /:/o);
    $ip =~ s/($IPv4Re)$/ipv4TOipv6($1)/eo;
    return $ip if ($ip !~ /::/o);
    my $col = $ip =~ tr/://;
    $col = 8 if $col > 8;
    $ip =~ s/^(.*)::(.*)$/($1||'0').':'.('0:'x(8-$col)).($2||'0')/oe;
    return $ip;
}
