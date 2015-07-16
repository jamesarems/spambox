#line 1 "sub main::activeRemoteSupport"
package main; sub activeRemoteSupport {
    open(my $F, '<', "$base/_enable.remote.support") or return;
    binmode $F;
    $RemoteSupportEnabled = <$F>;
    close $F;
    $RemoteSupportEnabled =~ s/\s|\r|\n//go;
    unlink "$base/_enable.remote.support";
    mlog(0,"admininfo: Remote Support is now enabled for connections from IP: $RemoteSupportEnabled - enable file $base/_enable.remote.support was removed");
}
