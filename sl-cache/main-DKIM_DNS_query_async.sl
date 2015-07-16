#line 1 "sub main::DKIM_DNS_query_async"
package main; sub DKIM_DNS_query_async {
	my ($domain, $type, %prms) = @_;

	my $callbacks = $prms{Callbacks} || {};
	my $on_success = $callbacks->{Success} || sub { $_[0] };
	my $on_error = $callbacks->{Error} || sub { die $_[0] };

	my $waiter = sub {
		my @resp;
		my $warning;
		eval {
			@resp = &main::DKIM_DNS_query($domain, $type);
			$warning = $@;
			undef $@;
		};
		$@ and return $on_error->($@);
		$@ = $warning;
		return $on_success->(@resp);
	};
	return $waiter;
}
