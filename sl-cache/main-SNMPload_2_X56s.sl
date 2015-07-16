#line 1 "sub main::SNMPload_2_X56s"
package main; sub SNMPload_2_X56s {
    my $name = shift;

    return $ConfigSync{$name}->{sync_cfg} if ($ConfigSync{$name}->{sync_cfg} < 1);
    my $syncserver = $ConfigSync{$name}->{sync_server};
    my $res = 0;
    while (my ($k,$v) = each %{$syncserver}) {
        if ($v == 1) {
            $res = $v;
            last;
        }
        $res |= $v;
    }
    return $res;
}
