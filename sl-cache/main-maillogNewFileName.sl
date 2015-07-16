#line 1 "sub main::maillogNewFileName"
package main; sub maillogNewFileName {
    my $fn;

    if ($FilesDistribution<1.0) {
        my $p1=1.0-$FilesDistribution;
        my $p2=log($FilesDistribution);
        $fn=int($MaxFiles*log(1.0-rand($p1))/$p2);
    } else {
        $fn=int($MaxFiles*rand());
    }
    return $fn;
}
