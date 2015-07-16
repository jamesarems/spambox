#line 1 "sub ASSP::CRYPT::_IH"
package ASSP::CRYPT; sub _IH {
	my ($s,$do) = @_;
    return $s unless $do;
    return join('',unpack 'H*',$s);
}
