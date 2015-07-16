#line 1 "sub main::decodeHTMLEntities"
package main; sub decodeHTMLEntities {
    my $s=shift;
    $s=~s/\&quot;?/\"/giso;
    $s=~s/\&gt;?/\>/giso;
    $s=~s/\&lt;?/\</giso;
    $s=~s/\&amp;?/\&/giso;
    return $s;
}
