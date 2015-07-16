#line 1 "sub ASSP::UUID::string_to_uuid"
package ASSP::UUID; sub string_to_uuid {
    my $uuid = shift;
    use bytes;
    return $uuid if length $uuid == 16;
    return MIME::Base64::decode_base64($uuid) if ($uuid =~ m/$IS_UUID_Base64/);
    my $str = $uuid;
    $uuid =~ s/^(?:urn:)?(?:uuid:)?//io;
    $uuid =~ tr/-//d;
    return pack 'H*', $uuid if $uuid =~ m/$IS_UUID_HEX/;
    return;
}
