#line 1 "sub main::ipNetwork"
package main; sub ipNetwork {
    my ($ip,$netblock)=@_;
    if ($ip =~ /:[^:]*:/o) {
        return ipv6expand($ip) if (!$netblock);
        $netblock = 64 if $netblock == 1;
        return join ':', map{my $t = sprintf("%x", oct("0b$_"));$t;} unpack 'a16' x 8, ipv6binary($ip,$netblock) . '0' x (128 - $netblock);
    } else {
        return $ip if (!$netblock);
        $netblock = 24 if $netblock == 1;
        my $u32 = unpack 'N', pack 'CCCC', split /\./o, $ip;
        my $mask = unpack 'N', pack 'B*', '1' x $netblock . '0' x (32 - $netblock );
        return join '.', unpack 'CCCC', pack 'N', $u32 & $mask;
    }
}
