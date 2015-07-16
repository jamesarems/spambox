#line 1 "sub SPAMBOX::CRYPT::_generate_sbox"
package SPAMBOX::CRYPT; sub _generate_sbox {
	my $self = shift;
	my $pspamboxhrase = shift;
	if (ref ($pspamboxhrase)) {
		@{$self->{SBOX}} = @$pspamboxhrase;
	} else {
		my ($i, $x, $y, $random, @tmp) = 0;
		my @temp = (0..15);
		for ($i=0; $i <= (length $pspamboxhrase); $i+=4)
		    { $random = $random ^ (unpack 'L', pack 'a4', substr ($pspamboxhrase, $i, $i+4)) };
		srand $random;
		for ($i=0; $i < 8; $i++) {
            @tmp = @temp;
            map { $x = _rand (15); $y = $tmp[$x]; $tmp[$x] = $tmp[$_]; $tmp[$_] = $y; } (0..15);
            map {$self->{SBOX}->[$i][$_] = $tmp[$_] } (0..15);
		}
	}
}
