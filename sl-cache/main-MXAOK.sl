#line 1 "sub main::MXAOK"
package main; sub MXAOK {
    my $fh = shift;
    return 1 unless $CanUseDNS && $DoDomainCheck;
    return MXAOK_Run($fh);
}
