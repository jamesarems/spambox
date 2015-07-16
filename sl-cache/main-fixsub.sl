#line 1 "sub main::fixsub"
package main; sub fixsub {
    my $s=shift;
    $s=~s/ {3,}/ lotsaspaces /go;
    my $t = $s;
    my $l = $s =~ s/(\S+)/ssub $1/go;
    "\n".($l > $HMMSequenceLength ? $t.' ':'').$s;
}
