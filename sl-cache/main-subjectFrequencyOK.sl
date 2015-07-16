#line 1 "sub main::subjectFrequencyOK"
package main; sub subjectFrequencyOK {
    my $fh = shift;
    return 1 unless $DoSameSubject;
    return 1 unless $subjectFrequencyInt;
    return 1 unless $subjectFrequencyNumSubj;
    return subjectFrequencyOK_Run($fh);
}
