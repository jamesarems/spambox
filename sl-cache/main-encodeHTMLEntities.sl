#line 1 "sub main::encodeHTMLEntities"
package main; sub encodeHTMLEntities {
    my $s=shift;
    $s=~s/\&/\&amp;/gso;
    $s=~s/\</\&lt;/gso;
    $s=~s/\>/\&gt;/gso;
    $s=~s/\"/\&quot;/gso;
    return $s;
}
