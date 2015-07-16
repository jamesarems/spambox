#line 1 "sub main::invalidHeloOK"
package main; sub invalidHeloOK {
    my ( $fh, $fhelo ) = @_;
    return 1 if !$DoInvalidFormatHelo;
    return invalidHeloOK_Run($fh, $fhelo);
}
