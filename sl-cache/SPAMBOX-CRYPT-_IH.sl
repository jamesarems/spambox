#line 1 "sub SPAMBOX::CRYPT::_IH"
package SPAMBOX::CRYPT; sub _IH {
	my ($s,$do) = @_;
    return $s unless $do;
    return join('',unpack 'H*',$s);
}
