#line 1 "sub SPAMBOX::UUID::version_of_uuid"
package SPAMBOX::UUID; sub version_of_uuid {
    my $uuid = shift;
    use bytes;
    $uuid = string_to_uuid($uuid);
    return (ord(substr($uuid, 6, 1)) & 0xf0) >> 4;
}
