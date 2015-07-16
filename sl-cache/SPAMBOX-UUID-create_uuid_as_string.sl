#line 1 "sub SPAMBOX::UUID::create_uuid_as_string"
package SPAMBOX::UUID; sub create_uuid_as_string {
    return uuid_to_string(create_uuid(@_));
}
