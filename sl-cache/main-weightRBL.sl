#line 1 "sub main::weightRBL"
package main; sub weightRBL {
    my $v = shift;
    if ($v) {
        return $v if $v >= 6;
        $v = int ($RBLmaxweight / $v + 0.5);
    } else {
        return 0;
    }
    return $v if $v;
    return int($RBLmaxweight / $RBLmaxhits + 0.5) if $RBLmaxweight && $RBLmaxhits;
    return ${'rblValencePB'}[0] ;
}
