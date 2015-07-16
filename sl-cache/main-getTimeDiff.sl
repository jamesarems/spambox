#line 1 "sub main::getTimeDiff"
package main; sub getTimeDiff {
	my ($tdiff,$seconds) = @_;
    my $m = getTimeDiffAsString($tdiff,$seconds);
    $m =~ s/^0 hours //o if ($m =~ s/^0 days //o);
    return $m;
}
