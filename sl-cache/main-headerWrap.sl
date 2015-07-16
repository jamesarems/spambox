#line 1 "sub main::headerWrap"
package main; sub headerWrap {
    my $header=shift;
    d('headerWrap');
    $header=~s/(?:([^\r\n]{60,75}?;)|([^\r\n]{60,75}) ) {0,5}(?=[^\r\n]{10,})/$1$2\r\n\t/go;

    return $header;
}
