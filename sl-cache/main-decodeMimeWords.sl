#line 1 "sub main::decodeMimeWords"
package main; sub decodeMimeWords {
    my $s = shift;
    headerUnwrap($s);
    $s =~ s/(=\?([^?]+)\?(b|q)\?([^?]*)\?=)/decodeMimeWord($1,$2,$3,$4)/gieo;
    return $s;
}
