#line 1 "sub SPAMBOX::CRYPT::_SYSV"
package SPAMBOX::CRYPT; sub _SYSV {
    my $d = shift;
    my $checksum = 0;
    foreach (split(//o,$d)) { $checksum += unpack("%16C*", $_) }
    $checksum %= 65535;
    return $checksum;
}
