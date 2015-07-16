#line 1 "sub main::iso2hex"
package main; sub iso2hex {
	my $s = shift;
    eval('
    use bytes;
    $s = join(\'\',unpack  \'H*\',$s);
    no bytes;');
    return $s;
}
