#line 1 "sub ASSP::UUID::_digest_as_octets"
package ASSP::UUID; sub _digest_as_octets {
    my $num_octets = shift;
    my $MD5_CALCULATOR = Digest::MD5->new();
    $MD5_CALCULATOR->add($_) for @_;
    return _fold_into_octets($num_octets, $MD5_CALCULATOR->digest);
}
