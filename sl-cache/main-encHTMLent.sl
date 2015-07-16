#line 1 "sub main::encHTMLent"
package main; sub encHTMLent {
    my $sh = shift;
    my $s = ref $sh ? $$sh : $sh;
    my $ret;
    eval{$ret = ($s ? &HTML::Entities::encode($s) : '');};
    if ($@) { # do what we can if HTML::Entities fails
         mlog(0,"warning: an error occured in encoding HTML-Entities - $@");
         $ret = encodeHTMLEntities($s);
    }
    return $ret ? $ret : $$s;
}
