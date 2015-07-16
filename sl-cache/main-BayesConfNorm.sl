#line 1 "sub main::BayesConfNorm"
package main; sub BayesConfNorm {
    my $c = abs(1 - $bayesnorm);
    my $exp = int($c * 10.0001);
    $exp = 4 if $exp > 4;
    return 1 / (($c + 1) ** $exp);
}
