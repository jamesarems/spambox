#line 1 "sub main::DKIMgen"
package main; sub DKIMgen {
    my $fh = shift;
    return unless $CanUseDKIM;
    return unless $genDKIM;
    return unless $Con{$fh}->{relayok};
    return if $Con{$fh}->{DKIMadded};
    return DKIMgen_Run($fh);
}
