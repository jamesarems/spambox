#line 1 "sub main::LocalSenderOK"
package main; sub LocalSenderOK {
    my ( $fh, $ip ) = @_;
    return 1 if ! $DoNoValidLocalSender;
    return 1 if ! $LocalAddresses_Flat && ! $DoLDAP && (! $DoVRFY || (! scalar(keys %DomainVRFYMTA) && ! scalar(keys %FlatVRFYMTA)));
    return LocalSenderOK_Run($fh, $ip);
}
