#line 1 "sub main::NumRcptOK"
package main; sub NumRcptOK {
    my($fh,$block)=@_;
    return 1 unless $DoMaxDupRcpt;
    return NumRcptOK_Run($fh,$block);
}
