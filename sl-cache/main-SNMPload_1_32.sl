#line 1 "sub main::SNMPload_1_32"
package main; sub SNMPload_1_32 {
    my @regerr = keys %RegexError;
    if (@regerr) {
        $subOID{'.1.32.0.0'} = 0;
        $subOID{'.1.32.0.1.0'} = "regex failed for: @regerr";
    } else {
        $subOID{'.1.32.0.0'} = 1;
        $subOID{'.1.32.0.1.0'} = 'all regular expressions are OK';
    }
    mlog(0,"info: SNMP read regular expression status OID .1.32.0") if $SNMPLog == 3;
    $subOIDLastLoad{'1.32'} = Time::HiRes::time() - 1;
}
