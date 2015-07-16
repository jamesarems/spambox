#line 1 "sub main::unicodeNormalizeRe"
package main; sub unicodeNormalizeRe {
    my ($re,$name) = @_;
    return unless $CanUseUnicodeNormalize && $normalizeUnicode && $] ge '5.012000';
    if (is_7bit_clean($re)) {
        return;
    }
    eval { $$re = d8($$re); };
    if (! utf8::valid($$re)) {
        mlog(0,"error: regular expression for '$name' is not UTF8 compatible");
        eval { $$re = e8($$re); };
        return;
    }
    my $norm = sub {
        local $_ = my $c = shift;
        unicodeNormalize_Run(\$c);
        return ($c eq $_) ? $_ : quotemeta($c);
    };
    $$re =~ s/([\P{Latin}]+)/$norm->($1)/goe;
    $$re = e8($$re);
}
