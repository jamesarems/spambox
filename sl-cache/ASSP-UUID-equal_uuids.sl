#line 1 "sub ASSP::UUID::equal_uuids"
package ASSP::UUID; sub equal_uuids {
    my ($u1, $u2) = @_;
    return unless defined $u1 && defined $u2;
    return string_to_uuid($u1) eq string_to_uuid($u2);
}
