#line 1 "sub main::normHTMLfile"
package main; sub normHTMLfile {
    my $s = shift;
    $s =~ s/([^\w\-.!~*\'() ])/sprintf("%%%02X",ord($1))/ego;
    $s =~ s/ /+/go;
    return $s;
}
