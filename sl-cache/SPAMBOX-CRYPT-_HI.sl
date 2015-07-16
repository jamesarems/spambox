#line 1 "sub SPAMBOX::CRYPT::_HI"
package SPAMBOX::CRYPT; sub _HI {
	my ($h,$do) = @_;
    return $h unless $do;
    return pack 'H*',$h;
}
