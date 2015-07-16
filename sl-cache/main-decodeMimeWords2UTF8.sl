#line 1 "sub main::decodeMimeWords2UTF8"
package main; sub decodeMimeWords2UTF8 {
    my $s = shift;
    headerUnwrap($s);
    $s =~ s/(=\?([^?]*)\?(b|q)\?([^?]+)\?=)/decodeMimeWord2UTF8($1,$2,$3,$4)/gieo;
    return $s;
}
