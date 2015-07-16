#line 1 "sub main::printScoreStats"
package main; sub printScoreStats {
    my ($name, $val) = @_;
    my $time = timestring('','','YYYY-MM-DD_hh:mm:ss');
    open(my $F, '>>', "$base/logs/scoreGraphStats_1.txt") or return;
    binmode $F;
    print $F "$time $name: $val\n";
    close $F;
    return;
}
