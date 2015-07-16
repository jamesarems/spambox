#line 1 "sub ASSP::UUID::create_uuid"
package ASSP::UUID; sub create_uuid {
    my $uuid;
    my $timestamp = Time::HiRes::time();
    my $clk_seq   = _get_clk_seq($timestamp);

    my $hi = int( $timestamp / 65536.0 / 512 * 78125 );
    $timestamp -= $hi * 512.0 * 65536 / 78125;
    my $low = int( $timestamp * 10000000.0 + 0.5 );

    if ( $low < 0xec7ec000 ) {
        $low += 0x13814000;
    }
    else {
        $low -= 0xec7ec000;
        $hi++;
    }

    if ( $hi < 0x0e4de22e ) {
        $hi += 0x01b21dd2;
    }
    else {
        $hi -= 0x0e4de22e;
    }

    substr $uuid, 0, 4, pack( 'N', $low );
    substr $uuid, 4, 2, pack( 'n', $hi & 0xffff );
    substr $uuid, 6, 2, pack( 'n', ( $hi >> 16 ) & 0x0fff );
    substr $uuid, 8, 2, pack( 'n', $clk_seq );
    substr $uuid, 10, 6, _random_node_id();

    substr $uuid, 6, 1, chr( ord( substr( $uuid, 6, 1 ) ) & 0x0f | 0x10 );
    substr $uuid, 8, 1, chr(ord(substr $uuid, 8, 1) & 0x3f | 0x80);
    return $uuid;
}
