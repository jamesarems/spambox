#line 1 "sub main::rmTree"
package main; sub rmTree {
    no warnings qw(recursion);
    my $dir = shift;
    my $count = 0;
    return 0 unless $dir;
    $dir =~ s/[\/\\]$//o;
    return 0 if $dir !~ /^\Q$base\E[\/\\]./o;
    return 0 if $protectSPAMBOX && $dir !~ /^\Q$base\E[\/\\][tT][eE]?[mM][pP]/o;
    return 0 unless $dF->($dir);
    foreach my $item ( $unicodeDH->($dir) ) {
        next unless $item;
        next if $item eq '.';
        next if $item eq '..';
        $item = $dir.'/'.$item;
        if ($dF->($item)) {
            $count += $rmtree->($item);
        } else {
            $count += $unlink->($item);
        }
    }
    $count += $rmdir->($dir);
    return $count;
}
