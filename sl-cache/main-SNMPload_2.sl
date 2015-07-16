#line 1 "sub main::SNMPload_2"
package main; sub SNMPload_2 {
    %subOID2Conf = ();
    my $j = scalar @ConfigArray;
    my $i = 0; my $lastid; my $h = -1;
    $ActWebSess = 'SNMP';
    $WebIP{$ActWebSess}->{user} = $SNMPUser;
    for ($i = 0;$i < $j;$i++) {
        if (@{$ConfigArray[$i]} == 5 && $ConfigArray[$i]->[3] =~ /heading/io) {
            $h++;
            $subOID{'.2.'.$h.'.0'} = [\&SNMPcleanHTML,\$ConfigArray[$i]->[4]];
            next;
        }
        my ($id) = $ConfigArray[$i]->[10] =~ /msg(\d{6})/o;
        $id =~ s/^0+//o;
        $id =~ s/0$//o;
        next unless $id;
        my $canSNMPDo = &canUserDo($SNMPUser,'cfg',$ConfigArray[$i]->[0]);
        next if ($SNMPUser ne 'root' && !$canSNMPDo && $AdminUsersRight{"$SNMPUser.user.hidDisabled"});
        $subOID{'.2.'.$h.'.'.$id.'.0'} = (($SNMPUser ne 'root' && exists $cryptConfigVars{$ConfigArray[$i]->[0]}) ? 'encrypted (ro)' : \$Config{$ConfigArray[$i]->[0]});
        my $li = '.0';
        if ($CreateMIB) {
            $subOID{'.2.'.$h.'.'.$id.'.1'} = \$ConfigArray[$i]->[0];
            $subOID{'.2.'.$h.'.'.$id.'.2'} = [\&SNMPcleanHTML,\$ConfigArray[$i]->[4]];
            $subOID{'.2.'.$h.'.'.$id.'.3'} = [\&SNMPcleanHTML,\$ConfigArray[$i]->[1]];
            $subOID{'.2.'.$h.'.'.$id.'.4'} = [\&SNMPcleanHTML,\$ConfigArray[$i]->[7]];
            $li = '.4';
        }
        if (&syncCanSync() or $CreateMIB) {
            my $ss = $ConfigSync{$ConfigArray[$i]->[0]}->{sync_cfg};
            $ss = 0 unless $ss;
            if ($ss > -1) {
                $subOID{'.2.'.$h.'.'.$id.'.5.0'} = [\&SNMPload_2_X56s,\$ConfigArray[$i]->[0]];
                $subOID{'.2.'.$h.'.'.$id.'.6.0'} = [\&SNMPload_2_X56,$i];
                $li = '.6.0';
            }
        }
        if (($SNMPUser eq 'root' || ($canSNMPDo && ! exists $cryptConfigVars{$ConfigArray[$i]->[0]})) &&
             $ConfigArray[$i]->[3] ne \&passnoinput &&
             $ConfigArray[$i]->[3] ne \&textnoinput
        ) {
            $subOID2Conf{'.2.'.$h.'.'.$id.'.0'} = $i;
        }
        $lastid = '.2.'.$h.'.'.$id.$li;
    }
    mlog(0,"info: SNMP read configuration OIDs .2.0 - $lastid") if $SNMPLog == 3;
    $subOIDLastLoad{2} = 9999999999;
}
