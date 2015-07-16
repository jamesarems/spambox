#line 1 "sub main::SNMPload_1_31"
package main; sub SNMPload_1_31 {
    my $tmpCount = 0;
    my $dbOK = 1;
    foreach my $s (keys %failedTable) {
        $dbOK = 0 if $failedTable{$s} > 1;
        $tmpCount++;
        $subOID{'.1.31.'.$tmpCount.'.0'} = ($failedTable{$s} > 1) ? 0 : 1;
        $subOID{'.1.31.'.$tmpCount.'.1.0'} = $s;
    }
    if (!$dbOK) {
         $subOID{'.1.31.0.0'} = 0;
         $subOID{'.1.31.0.1.0'} = 'failed database table(s)';
    } else {
         $subOID{'.1.31.0.0'} = 1;
         $subOID{'.1.31.0.1.0'} = 'database OK';
    }
    mlog(0,"info: SNMP read database status OIDs .1.31.0 - .1.31.$tmpCount") if $SNMPLog == 3;
    $subOIDLastLoad{'1.31'} = Time::HiRes::time() - 1;
}
