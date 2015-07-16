#line 1 "sub main::syncGetStatus"
package main; sub syncGetStatus {
    my $name = shift;

    return $ConfigSync{$name}->{sync_cfg} if ($ConfigSync{$name}->{sync_cfg} < 1);
    my $syncserver = $ConfigSync{$name}->{sync_server};
    my $res = 0;
    while (my ($k,$v) = each %{$syncserver}) {
        if ($v == 1) {
            $res = $v;
            last;
        } elsif ($v >= 2) {
            $v = 2;
        }
        $res |= $v;
    }
    return $res;
}
