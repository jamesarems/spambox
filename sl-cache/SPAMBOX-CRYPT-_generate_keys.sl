#line 1 "sub SPAMBOX::CRYPT::_generate_keys"
package SPAMBOX::CRYPT; sub _generate_keys {
	my ($self, $pspamboxhrase) = @_;
	if (ref ($pspamboxhrase)) {
		@{$self->{KEY}} = @$pspamboxhrase;
	} else {
		my ($i, $random) = 0;
		for ($i=0; $i <= (length $pspamboxhrase); $i+=4)
		    { $random = $random ^ (unpack 'L', pack 'a4', substr ($pspamboxhrase, $i, $i+4))};
		srand $random; map { $self->{KEY}[$_] = _rand (2**32) } (0..7);
	}
}
