#line 1 "sub main::unescape"
package main; sub unescape {
    my $string = shift;
    $string =~ s/\\//go;
    return $string;
}
