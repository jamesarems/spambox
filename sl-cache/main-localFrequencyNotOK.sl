#line 1 "sub main::localFrequencyNotOK"
package main; sub localFrequencyNotOK {
    my $fh = shift;
    return 0 unless $LocalFrequencyInt;
    return 0 unless $LocalFrequencyNumRcpt;
    return localFrequencyNotOK_Run($fh);
}
