#line 1 "sub main::SNMPload_1_30"
package main; sub SNMPload_1_30 {
    my %status = &WorkerStatus();
    foreach (keys %status) {
        if ($_ < 10000) {
            $subOID{'.1.30.'.$_.'.0'} = ($status{$_}{lastloop} < 180) ? 1 : 0;
        } else {
            $subOID{'.1.30.'.$_.'.0'} = $ComWorker{$_}->{run};
        }
        $subOID{'.1.30.'.$_.'.1.0'} = $status{$_}{lastloop};
        $subOID{'.1.30.'.$_.'.2.0'} = $status{$_}{lastaction};
    }
    mlog(0,"info: SNMP read worker status OIDs .1.30.1 - 1.30.10001.2") if $SNMPLog == 3;
    $subOIDLastLoad{'1.30'} = Time::HiRes::time() - 1;
}
