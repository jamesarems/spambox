#line 1 "sub main::FrequencyIPOK"
package main; sub FrequencyIPOK {
    my $fh = shift;
    return 1 if (! $DoFrequencyIP || ! $maxSMTPipConnects);
    return FrequencyIPOK_Run($fh);
}
