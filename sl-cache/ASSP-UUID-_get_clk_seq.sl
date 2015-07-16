#line 1 "sub ASSP::UUID::_get_clk_seq"
package ASSP::UUID; sub _get_clk_seq {
    my $ts = shift;
    _init_globals();
    if (defined $Last_Timestamp && $ts <= $Last_Timestamp) {
        $Clk_Seq = ($Clk_Seq + 1) & 0x3fff;
    }
    $Last_Timestamp = $ts;
    return $Clk_Seq;
}
