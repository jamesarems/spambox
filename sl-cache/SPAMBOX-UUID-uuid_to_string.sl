#line 1 "sub SPAMBOX::UUID::uuid_to_string"
package SPAMBOX::UUID; sub uuid_to_string {
    my $uuid = shift;
    use bytes;
    return $uuid if $uuid =~ m/$IS_UUID_STRING/;
    return unless length $uuid == 16;
    return join '-',
            map { unpack 'H*', $_ }
            map { substr $uuid, 0, $_, '' }
            ( 4, 2, 2, 2, 6 );
}
