#line 1 "sub ASSP::CRYPT::_HI"
package ASSP::CRYPT; sub _HI {
	my ($h,$do) = @_;
    return $h unless $do;
    return pack 'H*',$h;
}
