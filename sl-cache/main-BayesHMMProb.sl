#line 1 "sub main::BayesHMMProb"
package main; sub BayesHMMProb {
    my $t = shift;
    my $p1 = 1;
    my $p2 = 1;
    my $p1c = 1;
    my $p2c = 1;
    my $cc = 0;
    my $c1 = 0;
    my $max = $maxBayesValues;
    my $norm = BayesConfNorm();
    @$t = sort { abs( $main::b - .5 ) <=> abs( $main::a - .5 ) } @$t;
    while ($c1 < $max && scalar @$t) {
        my $p = shift(@$t);
        if ($p) {
            $p1 *= $p;
            $p2 *= ( 1 - $p );
            $c1++;
            if ($p < 0.01) {           # eliminate and count positive extreme ham values for confidence
                $cc++;
                next;
            }
            if ((1 - $p) < 0.01) {     # eliminate and count negative extreme spam values for confidence
                $cc--;
                next;
            }
            $p1c*=$p;                  # use the not extreme values for confidence calculation
            $p2c*=(1-$p);
        }
    }
    my $ps = $p1 + $p2;
    my $SpamProb = $ps ? ($p1 / $ps) : 1;       # default Bayesian math

    #  ignore    ham extremes if spam      and   spam extremes if ham for confidence calculation
    $cc = 0 if ($cc < 0 && $SpamProb > 0.5) or ($cc > 0 && $SpamProb <= 0.5);
    # use the spam/ham extremes left, to set a factor to reduce confidence
    $cc = 0.01 ** abs($cc);
    
    # found only extreme or no value -> set confidence to 1
    $p1c = 0 if ($p1c == 1 && $p2c == 1);

    # weight the confidence down, if not enough values are available ($c1/$maxBayesValues)**2
    my $SpamProbConfidence = abs( $p1c - $p2c ) * $cc * $norm * ($c1/$max) ** 2;
    $SpamProbConfidence = 1 if $SpamProbConfidence > 1;   # this should never happen -> but be save

    # return spampropval, hampropval, valcount, combined SpamProb, Confidence of combined SpamProb
    return ($p1,$p2,$c1,$SpamProb,$SpamProbConfidence);

#   $SpamProbConfidence = ((1+$p1-$p2)/2)*($c1/$max)**2;
}
