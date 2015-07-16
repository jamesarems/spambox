#line 1 "sub main::updateDNSServerLimit"
package main; sub updateDNSServerLimit {
    my ( $name, $old, $new, $init ) = @_;
    return '' if $WorkerNumber != 0 && $WorkerNumber != 10000;
    return '' if $WorkerNumber == 10000 && $ComWorker{$WorkerNumber}->{rereadconfig};
    mlog( 0, "AdminUpdate: $name - DNS configuration updated from '$old' to '$new'" )
      unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    updateDNS ( 'updateDNS', '', $Config{DNSServers}, $init ) unless $init;
    return '';
}
