#line 1 "sub SPAMBOX::UUID::_rand_32bit"
package SPAMBOX::UUID; sub _rand_32bit {
    _init_globals();
    my $v1 = int(rand(65536)) % 65536;
    my $v2 = int(rand(65536)) % 65536;
    return ($v1 << 16) | $v2;
}
