#line 1 "sub main::AUTHErrorsOK"
package main; sub AUTHErrorsOK {
    my $fh = shift;
    return 1 unless $MaxAUTHErrors;
    return AUTHErrorsOK_Run($fh);
}
