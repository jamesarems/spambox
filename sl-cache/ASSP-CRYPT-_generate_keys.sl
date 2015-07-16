#line 1 "sub ASSP::CRYPT::_generate_keys"
package ASSP::CRYPT; sub _generate_keys {
	my ($self, $passphrase) = @_;
	if (ref ($passphrase)) {
		@{$self->{KEY}} = @$passphrase;
	} else {
		my ($i, $random) = 0;
		for ($i=0; $i <= (length $passphrase); $i+=4)
		    { $random = $random ^ (unpack 'L', pack 'a4', substr ($passphrase, $i, $i+4))};
		srand $random; map { $self->{KEY}[$_] = _rand (2**32) } (0..7);
	}
}
