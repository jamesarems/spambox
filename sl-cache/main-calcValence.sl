#line 1 "sub main::calcValence"
package main; sub calcValence {
    my ($val, $valence) = @_;
    my @res = ($val);
    unless (${$valence}[1]) {
        push @res ,0;
        return \@res;
    }
    unless (${$valence}[0]) {
        push @res, $val;
        return \@res;
    }
    push @res, (int($val * ${$valence}[1] / ${$valence}[0] + 0.5));
    return \@res;
}
