#line 1 "sub main::SNMPload_3"
package main; sub SNMPload_3 {
    my ($dummy,@modules) = &StatsGetModules();
    my $i = 0;
    while (@modules){
        my $m = shift @modules;
        $m->[1] =~ s/<\/?a[^>]*>//o;
        $m->[1] =~ s/<\/?font[^>]*>//o;
        $m->[2] =~ s/<\/?font[^>]*>//o;
        $m->[3] =~ s/<\/?font[^>]*>//o;
        $subOID{'.3.'.$i.'.0'} = $m->[0];
        for (my $j = 1;$j < 5;$j++) {
            $subOID{'.3.'.$i.'.'.$j.'.0'} = $m->[$j];
        }
        $i++;
    }
    $i--;
    mlog(0,"info: SNMP read perl module configuration OIDs .3.0.0 - 3.$i.4") if $SNMPLog == 3;
    $subOIDLastLoad{3} = 9999999999;
}
