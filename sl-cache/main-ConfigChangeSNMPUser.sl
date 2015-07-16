#line 1 "sub main::ConfigChangeSNMPUser"
package main; sub ConfigChangeSNMPUser {my ($name, $old, $new, $init)=@_;
    return if $WorkerNumber != 0;
    if ($new ne $old or $init) {
        delete $WebIP{SNMP};
        mlog(0,"AdminUpdate: $name changed from $old to $new") unless $init;
        $SNMPUser = $Config{SNMPUser} = $new;
    }
    return '';
}
