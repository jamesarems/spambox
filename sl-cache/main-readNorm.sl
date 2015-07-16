#line 1 "sub main::readNorm"
package main; sub readNorm {
    if (!$lockBayes && exists $Spamdb{'***bayesnorm***'}) {
        $bayesnorm = $Spamdb{'***bayesnorm***'};
        return;
    }
    return if $lockBayes && $bayesnorm;
    if (!$lockHMM && exists $HMMdb{'***bayesnorm***'}) {
        $bayesnorm = $HMMdb{'***bayesnorm***'};
        return;
    }
    open (my $F, '<', "$base/normfile") or return 1;
    binmode $F;
    my @t = split(/ /,join('',<$F>));
    close $F;
    $t[0] ||= 1;
    $bayesnorm = $t[0];
    threads->yield;
}
