#line 1 "sub SPAMBOX::UUID::_random_node_id"
package SPAMBOX::UUID; sub _random_node_id {
    my $self = shift;
    my $r1 = _rand_32bit();
    my $r2 = _rand_32bit();
    my $hi = ($r1 >> 8) ^ ($r2 & 0xff);
    my $lo = ($r2 >> 8) ^ ($r1 & 0xff);
    $hi |= 0x80;
    my $id  = substr pack('V', $hi), 0, 3;
       $id .= substr pack('V', $lo), 0, 3;
    return $id;
}
