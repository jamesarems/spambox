#line 1 "sub ASSP::CRYPT::_generate_sbox"
package ASSP::CRYPT; sub _generate_sbox {
	my $self = shift;
	my $passphrase = shift;
	if (ref ($passphrase)) {
		@{$self->{SBOX}} = @$passphrase;
	} else {
		my ($i, $x, $y, $random, @tmp) = 0;
		my @temp = (0..15);
		for ($i=0; $i <= (length $passphrase); $i+=4)
		    { $random = $random ^ (unpack 'L', pack 'a4', substr ($passphrase, $i, $i+4)) };
		srand $random;
		for ($i=0; $i < 8; $i++) {
            @tmp = @temp;
            map { $x = _rand (15); $y = $tmp[$x]; $tmp[$x] = $tmp[$_]; $tmp[$_] = $y; } (0..15);
            map {$self->{SBOX}->[$i][$_] = $tmp[$_] } (0..15);
		}
	}
}
