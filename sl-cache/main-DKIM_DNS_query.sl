#line 1 "sub main::DKIM_DNS_query"
package main; sub DKIM_DNS_query {
	my ($domain, $type) = @_;
	my $resp = &main::queryDNS($domain, $type);
	if (ref $resp)
	{
		my @result = eval{grep { lc $_->type eq lc $type } $resp->answer};
		return @result if @result;
	}
    return ();
}
