#line 1 "sub main::RBLCacheOK"
package main; sub RBLCacheOK {
    my ($fh,$ip,$skipcip) = @_;
    return 1 if !$ValidateRBL;
    return 1 if !$RBLCacheExp;
    return RBLCacheOK_Run($fh,$ip,$skipcip);
}
