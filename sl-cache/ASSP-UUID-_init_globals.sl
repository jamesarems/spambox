#line 1 "sub ASSP::UUID::_init_globals"
package ASSP::UUID; sub _init_globals {
    if (!defined $Last_Pid || $Last_Pid != $$) {
        $Last_Pid = $$;
        for (my $i = 0; $i <= 5; $i++) {
            my $new_clk_seq = _generate_clk_seq();
            if (!defined($Clk_Seq) || $new_clk_seq != $Clk_Seq) {
                $Clk_Seq = $new_clk_seq;
                last;
            }
        }
    }
    return;
}
