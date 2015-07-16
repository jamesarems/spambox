#line 1 "sub main::unicodeNormalize_Run"
package main; sub unicodeNormalize_Run {
    my $s = shift;
    $$s =~ s/([\P{Latin}]+)/unicodeNFKC($1)/goe;
}
