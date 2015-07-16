#line 1 "sub main::decodeMimeWord"
package main; sub decodeMimeWord {
    my ($fulltext,$charset,$encoding,$text)=@_;
    my $ret;

    eval {$charset = Encode::resolve_alias(uc($charset));} if $charset;

    if (! $@ && $CanUseEMM && $charset ) {
        eval{$ret = MIME::Words::decode_mimewords($fulltext)} if $fulltext;
        return $ret unless $@;
    }

    if (lc $encoding eq 'b') {
        $text=base64decode($text);
    } elsif (lc $encoding eq 'q') {
        $text=~s/_/\x20/go; # RFC 1522, Q rule 2
        $text=~s/=([\da-fA-F]{2})/pack('C', hex($1))/geo; # RFC 1522, Q rule 1
    };
    return $text;
}
