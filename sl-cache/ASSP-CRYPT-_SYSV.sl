#line 1 "sub ASSP::CRYPT::_SYSV"
package ASSP::CRYPT; sub _SYSV {
    my $d = shift;
    my $checksum = 0;
    foreach (split(//o,$d)) { $checksum += unpack("%16C*", $_) }
    $checksum %= 65535;
    return $checksum;
}
