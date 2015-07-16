#line 1 "sub main::RWLok"
package main; sub RWLok {
    my($fh,$ip)=@_;
    return 1 if ! $CanUseRWL;
    return 1 if ! $ValidateRWL;
    return 1 if ! @rwllist;
    return RWLok_Run($fh,$ip);
}
