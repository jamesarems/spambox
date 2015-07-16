#line 1 "sub main::getUniWords"
package main; sub getUniWords {
    my $word = shift;
    return $word if ($] lt '5.012000');
    my @chars;
    Encode::_utf8_on($word);
    unicodeNormalize(\$word);
    Encode::_utf8_on($word);
    if (eval{$word =~ /^(?:$NonSymLangRE)+$/o;}) {    # return the word - this is not a symbol language
        Encode::_utf8_off($word);
        return $word;
    }
    if ($CanUseUnicodeGCString) {
        eval{$word = join('', map {my $t = $_; utf8::encode($t) unless utf8::valid($t); $t;} split(//o,$word) );};
        Encode::_utf8_on($word);
        if (! utf8::valid($word)) {
            Encode::_utf8_off($word);
            return $word;
        }
        if ($debug) {
            open(my $F , '>', "$base/debug/last_unicode_bayes_word.txt");
            binmode $F;
            eval{print $F $word;};
            close $F;
        }
        eval{@chars = map {my $t = $_->as_string;$t;} Unicode::GCString->new($word)->as_array;};
    }
    eval{@chars = split(//o,$word);} unless @chars;
    if (eval{$word !~ /$NonSymLangRE/o;}) {  # return symbols - all characters are from a symbol language
        Encode::_utf8_off($_) for @chars;
        return @chars;
    }
    $word = '';
    my @ret;
    for (@chars) {            # separate mixed contents in to separate words - try best fit
        next unless $_;
        my $issym;
        eval{$issym = $_ !~ /$NonSymLangRE/o;};
        Encode::_utf8_off($_);
        if (! $issym) {
            $word .= $_;
        } else {
            if ($word) {
                push @ret, $word;
                $word = '';
            }
            push @ret, $_;
        }
    }
    push @ret, $word if $word;
    return @ret;
}
