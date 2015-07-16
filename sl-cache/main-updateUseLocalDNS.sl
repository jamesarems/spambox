#line 1 "sub main::updateUseLocalDNS"
package main; sub updateUseLocalDNS {
    my ( $name, $old, $new, $init ) = @_;
    my $ret;
    ${$name} = $Config{$name} = $new;
    unless ($init || $new eq $old) {
        mlog( 0, "AdminUpdate: $name updated from '$old' to '$new'" );
        $ret = updateDNS ( 'updateDNS', '', $Config{DNSServers}, $init );
    }
    return $ret;
}
