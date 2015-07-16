#line 1 "sub main::PTROK"
package main; sub PTROK {
    my $fh = shift;
    return 1 if !$DoReversed;
    return 1 if !$CanUseDNS;
    return PTROK_Run($fh);
}
