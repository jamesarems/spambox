#line 1 "sub SPAMBOX::UUID::is_uuid_string"
package SPAMBOX::UUID; sub is_uuid_string {
    my $uuid = shift;
    return $uuid =~ m/$IS_UUID_STRING/;
}
