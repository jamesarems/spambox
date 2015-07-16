#line 1 "sub main::PBOK"
package main; sub PBOK {
    my($fh,$myip) = @_;
    return 1 if ! $DoPenalty;
    return PBOK_Run($fh,$myip);
}
