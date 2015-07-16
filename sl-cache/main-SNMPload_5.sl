#line 1 "sub main::SNMPload_5"
package main; sub SNMPload_5 {
    if ($CreateMIB or $SNMPUser eq 'root' or &canUserDo($SNMPUser,'action','SNMPAPI')) {
         my $baseOID = NetSNMP::OID->new($SNMPBaseOID);
         $subOID{'.5.0.0'} = '' unless exists $subOID{'.5.0.0'};
         $subOID{'.5.1.0'} = \$lastSNMPAPIresult;
         $canSNMPAPI = 1;
         $maxOID = $baseOID . '.5.1.0';
         mlog(0,"info: SNMP registered API OIDs .5.0.0 - 5.1.0") if $SNMPLog == 3;
    }
    $subOIDLastLoad{5} = Time::HiRes::time() - 5;
}
