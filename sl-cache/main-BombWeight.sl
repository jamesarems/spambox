#line 1 "sub main::BombWeight"
package main; sub BombWeight {
    my ($fh,$t,$re) = @_;
    my %weight = ();
    mlog(0,"error: code error - missing valence value in 'WeightedRe' hash in sub BombWeight for $re") if (! exists $WeightedRe{$re});
    mlog(0,"warning: suspect valence value '0' in 'WeightedRe' hash for '$WeightedRe{$re}' in sub BombWeight for $re") if $BombLog >= 2 && ${$WeightedRe{$re}}[0] == 0;
    return %weight unless ${$re};
    return %weight unless ${$re.'RE'};
    return BombWeight_Run($fh,$t,$re);
}
