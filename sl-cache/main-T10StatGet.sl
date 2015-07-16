#line 1 "sub main::T10StatGet"
package main; sub T10StatGet {
    my ($h,$max) = @_;
    my @th;
    my $count = 0;
    foreach my $c (sort {${'T10Stat'.$h}{$main::b} <=> ${'T10Stat'.$h}{$main::a}} keys %{'T10Stat'.$h}) {
        push @th , $c , ${'T10Stat'.$h}{$c};
        last if ++$count == $max;
    }
    return @th;
}
