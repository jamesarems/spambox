#line 1 "sub ASSP::CRYPT::_XOR_SYSV"
package ASSP::CRYPT; sub _XOR_SYSV {
    my ($d,$bin) = @_;
    my $xor = 0x03 ^ 0x0d;
    map { $xor ^= ord($_); } split(//o, $d);
    return _HI(sprintf ("%02x", $xor),$bin) . _HI(sprintf("%04x",unpack("%32W*",$d) % 65535),$bin);
}
