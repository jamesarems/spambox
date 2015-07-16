#line 1 "sub main::RBLok"
package main; sub RBLok {
    my ($fh,$ip,$skipcip) = @_;
    return 1 if ! $ValidateRBL;
    return 1 if ! $CanUseRBL;
    return 1 if ! @rbllist;
    return RBLok_Run($fh,$ip,$skipcip);
}
