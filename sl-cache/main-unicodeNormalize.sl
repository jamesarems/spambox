#line 1 "sub main::unicodeNormalize"
package main; sub unicodeNormalize {
    my $s = shift;
    return unless $CanUseUnicodeNormalize && $normalizeUnicode && $] ge '5.012000';
    if (is_7bit_clean($s)) {
        return;
    }
    eval { $$s = d8($$s); };
    if (! utf8::valid($$s)) {
        $$s = e8($$s);
        return;
    }
    unicodeNormalize_Run($s);
    $$s = e8($$s);
}
