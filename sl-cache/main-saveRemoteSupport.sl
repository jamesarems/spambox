#line 1 "sub main::saveRemoteSupport"
package main; sub saveRemoteSupport {
    return unless $RemoteSupportEnabled;
    open(my $F, '>', "$base/_enable.remote.support") or return;
    binmode $F;
    print $F $RemoteSupportEnabled;
    close $F;
    mlog(0,"admininfo: enabled Remote Support state: $RemoteSupportEnabled was saved to file $base/_enable.remote.support");
}
