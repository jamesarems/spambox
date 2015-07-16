#line 1 "sub main::MsgIDOK"
package main; sub MsgIDOK {
    my $fh = shift;
    return 1 if ! $DoMsgID;
    return MsgIDOK_Run($fh);
}
