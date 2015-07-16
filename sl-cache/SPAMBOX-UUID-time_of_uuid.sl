#line 1 "sub SPAMBOX::UUID::time_of_uuid"
package SPAMBOX::UUID; sub time_of_uuid {
    my $uuid = shift;
    use bytes;
    $uuid = string_to_uuid($uuid);
    return unless version_of_uuid($uuid) == 1;

    my $low = unpack 'N', substr($uuid, 0, 4);
    my $mid = unpack 'n', substr($uuid, 4, 2);
    my $high = unpack('n', substr($uuid, 6, 2)) & 0x0fff;

    my $hi = $mid | $high << 16;

    if ($low >= 0x13814000) {
        $low -= 0x13814000;
    }
    else {
        $low += 0xec7ec000;
        $hi --;
    }

    if ($hi >= 0x01b21dd2) {
        $hi -= 0x01b21dd2;
    }
    else {
        $hi += 0x0e4de22e;
    }

    $low /= 10000000.0;
    $hi  /= 78125.0 / 512 / 65536;

    return $hi + $low;
}
