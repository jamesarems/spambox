#line 1 "sub main::SNMPload_2_X56"
package main; sub SNMPload_2_X56 {
    my $i = shift;
    my $server = $ConfigSync{$ConfigArray[$i]->[0]}->{sync_server};
    my $msg = $ConfigArray[$i]->[0].':='.$ConfigSync{$ConfigArray[$i]->[0]}->{sync_cfg};
    while (my ($k,$v) = each %{$server}) {
        $msg .= ",$k=$v";
    }
    return $msg;
}
