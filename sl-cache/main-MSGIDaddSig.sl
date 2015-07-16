#line 1 "sub main::MSGIDaddSig"
package main; sub MSGIDaddSig {
    my ($fh,$msgid) = @_;
    return $msgid unless $DoMSGIDsig;
    return $msgid unless $CanUseSHA1;
    return $msgid unless $msgid;
    return $msgid unless $fh;
    return MSGIDaddSig_Run($fh,$msgid);
}
