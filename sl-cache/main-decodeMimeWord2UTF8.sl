#line 1 "sub main::decodeMimeWord2UTF8"
package main; sub decodeMimeWord2UTF8 {
    my ($fulltext,$charset,$encoding,$text)=@_;
    my $ret;

    eval { $charset = Encode::resolve_alias(uc($charset));
           $charset .= endian(\$text,uc($charset)) if uc($charset) =~ /^(?:UTF[_-]?(?:16|32)|UCS[_-]?[24])$/o;
         } if $charset;

    if (!$@ && $CanUseEMM && $charset ) {
        eval{$ret = MIME::Words::decode_mimewords($fulltext)} if $fulltext;
        eval{
            $ret = Encode::decode($charset, $ret);
            $ret = e8($ret) if $ret;
        } if $ret;
        return $ret unless $@;
    }

    if (lc $encoding eq 'b') {
        $text=base64decode($text);
    } elsif (lc $encoding eq 'q') {
        $text=~s/_/\x20/go; # RFC 1522, Q rule 2
        $text=~s/=([\da-fA-F]{2})/pack('C', hex($1))/geo; # RFC 1522, Q rule 1
    };
    eval{
        $text = Encode::decode($charset, $text);
        $text = e8($text) if $text;
    } if $text;
    return $text;
}
