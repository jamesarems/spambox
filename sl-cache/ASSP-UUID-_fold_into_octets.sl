#line 1 "sub ASSP::UUID::_fold_into_octets"
package ASSP::UUID; sub _fold_into_octets {
    use bytes;
    my ($num_octets, $s) = @_;
    my $x = "\x0" x $num_octets;
    while (length $s > 0) {
        my $n = '';
        while (length $x > 0) {
            my $c = ord(substr $x, -1, 1, '') ^ ord(substr $s, -1, 1, '');
            $n = chr($c) . $n;
            last if length $s <= 0;
        }
        $n = $x . $n;
        $x = $n;
    }

    return $x;
}
