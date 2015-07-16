#line 1 "sub main::MSGIDsigOK"
package main; sub MSGIDsigOK {
    my $fh = shift;
    return 1 if ! $DoMSGIDsig;
    return 1 if ! $CanUseSHA1;
    return MSGIDsigOK_Run($fh);
}
