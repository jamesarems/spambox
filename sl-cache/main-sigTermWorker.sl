#line 1 "sub main::sigTermWorker"
package main; sub sigTermWorker {
    my $sig = shift;
    return unless $sig;
    local $_ = undef;
    local @_ = ();
    local $/ = undef;
    die "TERMINATED - possibly by MainThread on detect stuck\n";
}
