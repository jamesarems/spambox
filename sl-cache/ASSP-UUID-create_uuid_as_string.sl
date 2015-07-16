#line 1 "sub ASSP::UUID::create_uuid_as_string"
package ASSP::UUID; sub create_uuid_as_string {
    return uuid_to_string(create_uuid(@_));
}
