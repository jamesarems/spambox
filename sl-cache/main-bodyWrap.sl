#line 1 "sub main::bodyWrap"
package main; sub bodyWrap {
    my $cont = shift;
    my $max = shift;
    d('bodyWrap');
    my $body = substr($$cont,0,$max);
    return \$body if $body =~ /[\x7F-\xFF]/o;  # binary data
    $body =~ s/\n+[^\n]+$/\n/o;                # remove last unterminated line
    return \$body;
}
