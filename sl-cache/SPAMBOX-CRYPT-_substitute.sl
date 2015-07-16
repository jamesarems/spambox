#line 1 "sub SPAMBOX::CRYPT::_substitute"
package SPAMBOX::CRYPT; sub _substitute {
	my ($self, $d) = @_;
	my $return = 0;
	map {$return |= $self->{SBOX}->[$_][$d >> ($_ << 2) & 15] << ($_ << 2)} reverse (0..7);
    return $return << 11 | $return >> 21;
}
