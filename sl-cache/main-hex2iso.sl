#line 1 "sub main::hex2iso"
package main; sub hex2iso {
	my $h = shift;
    eval('
    use bytes;
    $h = pack \'H*\',$h;
    no bytes;');
    return $h;
}
