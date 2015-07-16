#line 1 "sub main::normHTML"
package main; sub normHTML {
    my $s = shift;
    $s =~ s/([^a-zA-Z0-9])/sprintf("%%%02X", ord($1))/eog;
    return $s;
}
