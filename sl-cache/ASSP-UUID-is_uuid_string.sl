#line 1 "sub ASSP::UUID::is_uuid_string"
package ASSP::UUID; sub is_uuid_string {
    my $uuid = shift;
    return $uuid =~ m/$IS_UUID_STRING/;
}
