#line 1 "sub main::GRIPvalue"
package main; sub GRIPvalue {
    my ( $fh, $ip ) = @_;
    return 1 if ! $griplist;
    return 1 if ! (${'gripValencePB'}[0] || ${'gripValencePB'}[1]);
    return GRIPvalue_Run( $fh, $ip );
}
