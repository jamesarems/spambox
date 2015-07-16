#line 1 "sub main::getheaderLength"
package main; sub getheaderLength {
    my $fh = shift;
    return 0 unless $fh;
    my $l = 0;
    if (ref($fh) && ref($fh) ne 'SCALAR' && exists $Con{$fh}) {
        return 0 unless $Con{$fh}->{headerpassed};
        $l = index($Con{$fh}->{header}, "\x0D\x0A\x0D\x0A");
        return ($l >= 0 ? $l + 4 : 0);
    }
    return 0 unless length(ref($fh)?$$fh:$fh);
    $l = index((ref($fh)?$$fh:$fh), "\x0D\x0A\x0D\x0A");
    return ($l >= 0 ? $l + 4 : 0);
}
