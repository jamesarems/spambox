#line 1 "sub main::sigToMainThread"
package main; sub sigToMainThread {
    my $sig = shift;
    return unless $sig;
    local $_ = undef;
    local @_ = ();
    local $/ = undef;
    mlog(0,"info: got signal '$sig' - send it to MainThread");
    $mtObj->kill($sig);
    return;
}
