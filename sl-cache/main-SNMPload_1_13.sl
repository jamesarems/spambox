#line 1 "sub main::SNMPload_1_13"
package main; sub SNMPload_1_13 {
    my $ret;
    while (my ($k,$v) = each %RunTaskNow) {
        next unless $k && $v;
        $ret .= "$v ";
    }
    return $ret;
}
