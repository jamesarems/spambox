#line 1 "sub main::PersBlackOK"
package main; sub PersBlackOK {
    my $fh = shift;
    return 1 unless $persblackdb;
    return 1 unless $PersBlackHasRecords;
    return PersBlackOK_Run($fh);
}
