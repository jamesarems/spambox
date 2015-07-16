#line 1 "sub main::BombHeaderOK"
package main; sub BombHeaderOK {
    my ($fh,$bd) = @_;
    return 1 if !$DoBombHeaderRe;
    return BombHeaderOK_Run($fh,$bd);
}
