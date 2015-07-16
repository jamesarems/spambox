#line 1 "sub main::ConfigChangeTLSPorts"
package main; sub ConfigChangeTLSPorts {my ($name, $old, $new, $init)=@_;
    return '' if $new eq $old && ! $init;

    $$name = $Config{$name} = $new unless $WorkerNumber;
    mlog(0,"AdminUpdate: $name changed to $new from $old") if $WorkerNumber == 0 && ! $init;
    my $listen = $name eq 'NoTLSlistenPorts' ? 'lsnNoTLSI' : 'TLStoProxyI';
    fillPortArray($listen, $new);
    return '';
}
