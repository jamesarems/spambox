#line 1 "sub main::validHeloOK"
package main; sub validHeloOK {
    my ( $fh, $fhelo ) = @_;
    return 1 if !$DoValidFormatHelo;
    return validHeloOK_Run($fh, $fhelo);
}
