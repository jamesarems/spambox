#line 1 "sub SPAMBOX::UUID::clk_seq_of_uuid"
package SPAMBOX::UUID; sub clk_seq_of_uuid {
    use bytes;
    my $uuid = shift;
    $uuid = string_to_uuid($uuid);
    return unless version_of_uuid($uuid) == 1;

    my $r = unpack 'n', substr($uuid, 8, 2);
    my $v = $r >> 13;
    my $w = ($v >= 6) ? 3 # 11x
          : ($v >= 4) ? 2 # 10-
          :             1 # 0--
          ;
    $w = 16 - $w;

    return $r & ((1 << $w) - 1);
}
