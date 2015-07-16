#line 1 "sub main::NotifyFrequencyOK"
package main; sub NotifyFrequencyOK {
    my $text = shift;
    return 1 if eval{$DEBUG && $DEBUG->opened;};
    return 1 unless keys %NotifyFreqTF;
    return 1 if $text !~ /^(info|warning|error)\s*:/oi;
    return 1 unless $NotifyFreqTF{$1};
    return 0 if $NotifyLastFreq{$1} + $NotifyFreqTF{$1} > time;
    $NotifyLastFreq{$1} = time;
    return 1;
}
