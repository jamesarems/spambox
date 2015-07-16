#line 1 "sub main::BayesWordClean"
package main; sub BayesWordClean {
    my $word = lc(shift);
    return unless $word;
    no warnings;
#    if (! is_7bit_clean(\$word) && ! Encode::is_utf8($word)) {
#        Encode::_utf8_on($word);
#        if (! $debugWordEncoding && ! Encode::is_utf8($word,1)) {
#            $word = eval { Encode::decode('utf8', Encode::encode('utf8', $word), FB_SPACE); };
#        }
#        if ($debugWordEncoding && ! Encode::is_utf8($word,1)) {
#            open(my $F, '>>', "$base/debug/_enc_susp.txt");
#            binmode $F;
#            print $F $word.' - o<'.Encode::is_utf8($word).">\n";
#            $word = Encode::encode('utf8', $word);
#            print $F $word.' - e<'.Encode::is_utf8($word).">\n";
#            $word = Encode::decode('utf8', $word, FB_SPACE);
#            print $F $word.' - d<'.Encode::is_utf8($word).">\n";
#            close $F;
#        }
#    }
#    return unless $word;
    eval {$word = substr($word,0,length($word));};
    my @words;
    my $e = $@;
    eval{
        if ($word =~ /^$EmailAdrRe\@$EmailDomainRe$/io) {    # email addresses are too long -> MD5 (24 Byte hex)
            Encode::_utf8_off($word);
            $word = lc substr(Digest::MD5::md5_hex($word),0,24);
        } elsif ($word =~ /^.*?(?:ht|f)tps?:\/\/($EmailDomainRe)([\?\&\/].*)?$/io && length($1) > 1) {    # get URL's
            $word = $1;
            my $text = $2;
            Encode::_utf8_off($word);
            Encode::_utf8_off($text);
            push(@words,$word) for (2..$HMMSequenceLength);
            for my $w (split(/[\/#?=&]+/o,$text)) {
                next if length($w) < 2;
                push(@words,$w);
                last if (scalar @words == ($HMMSequenceLength + 1));
            }
        } else {
            BayesCharClean(\$word);
        }
        1;
    } or do {$@ = $e; return};
    Encode::_utf8_off($word);
    unshift @words, $word;
    @words = map { getUniWords($_); } @words;
    BayesCharClean(\$_) for @words;
    return @words;
}
