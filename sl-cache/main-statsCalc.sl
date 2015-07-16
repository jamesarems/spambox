#line 1 "sub main::statsCalc"
package main; sub statsCalc {
    my ($src, $srclist) = @_;
    my @res;
    for my $s (0..(scalar(@$src)-1)) {
        push @res, 0;
        for my $t (0..(scalar(@$srclist)-1)) {
            $res[$s] += $src->[$s]->{$srclist->[$t]};
        }
    }
    return @res;
}
