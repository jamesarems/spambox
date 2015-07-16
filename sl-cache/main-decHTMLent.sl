#line 1 "sub main::decHTMLent"
package main; sub decHTMLent {
    my $sh = shift;
    my $s = ref $sh ? $$sh : $sh;
    my $ret;

    $s =~ s/\&nbsp;?/ /gosi;  # decode &nbsp; to space not to \160
    $s =~ s/\&shy;?/-/gosi;   # decode &shy; to '-' not to \173

    $s =~ s/\&\#(\d+);?/&decHTMLentHD($1)/geo;
    $s =~ s/\&\#x([a-f0-9]+);?/&decHTMLentHD($1,'hex')/geio;
    $s =~ s/([^\\])?\\(\d{1,3});?/$1.&decHTMLentHD($2,'oct')/geio;
    $s =~ s/([^\\])?[%=]([a-f0-9]{2});?/$1.&decHTMLentHD($2,'hex')/gieo;

    my $e = $@;   #local $@ = undef; was not working on perl 5.12
    eval{$ret = &HTML::Entities::decode($s);} if $s;
    if ($@) { # do what we can if HTML::Entities fails
         mlog(0,"warning: an error occured in decoding HTML-Entities - $@");
         $ret = decodeHTMLEntities($s);
    }
    $@ = $e;
    return $ret ? $ret : $s;
}
