#line 1 "sub main::SNMPload_4"
package main; sub SNMPload_4 {
    my $maxsubOID = &SNMPStats('.4.1','.4.2','.4.3','.4.4',undef,undef);
    $maxsubOID    = &SNMPStats(undef,undef,undef,undef,'.4.5','.4.6') || $maxsubOID;
    my $baseOID = NetSNMP::OID->new($SNMPBaseOID);
    $maxOID = $baseOID . $maxsubOID;
    mlog(0,"info: SNMP read Stat OIDs .4.1.1.0 - $maxsubOID") if $SNMPLog == 3;
    $subOIDLastLoad{4} = Time::HiRes::time() - 1;
}
