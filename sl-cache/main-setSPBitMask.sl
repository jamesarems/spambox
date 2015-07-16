#line 1 "sub main::setSPBitMask"
package main; sub setSPBitMask {
    my ($whash,$res,$w,$name) = @_;

    my (@b0,@b1,@b2,@b3);
    my @r = split(/\./o,$res);
    @b0 = setSPBitMaskNum($r[0],$name);
    @b1 = setSPBitMaskNum($r[1],$name);
    @b2 = setSPBitMaskNum($r[2],$name);
    @b3 = setSPBitMaskNum($r[3],$name);
    if (@b0 && @b1 && @b2 && @b3) {
        for my $b0 (@b0) { for my $b1 (@b1) { for my $b2 (@b2) { for my $b3 (@b3) { $whash->{"$b0.$b1.$b2.$b3"} += $w; }}}}
    }
}
