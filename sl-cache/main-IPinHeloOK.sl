#line 1 "sub main::IPinHeloOK"
package main; sub IPinHeloOK {
    my $fh = shift;
    return 1 if !$DoIPinHelo;
    return IPinHeloOK_Run($fh);
}
