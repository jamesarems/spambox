#line 1 "sub main::unicodeNFKC"
package main; sub unicodeNFKC {
    my $s = shift;
    my $c = chr(0x24FF);
    eval {
    # first we do, what Unicode::Normalize is not doing like we want it
    $s =~ s/$c/0/go;

    for (0x24F5...0x24FE) {$c = chr($_); $s =~ s/$c/$_ - 0x24F4/ge;}   # 1 - 10
    for (0x2776...0x277F) {$c = chr($_); $s =~ s/$c/$_ - 0x2775/ge;}   # 1 - 10
    for (0x2780...0x2789) {$c = chr($_); $s =~ s/$c/$_ - 0x2779/ge;}   # 1 - 10
    for (0x278A...0x2793) {$c = chr($_); $s =~ s/$c/$_ - 0x2789/ge;}   # 1 - 10
    for (0x3220...0x3229) {$c = chr($_); $s =~ s/$c/'('.($_ - 0x321F).')'/ge;}   # (1 - 10)

    for (0x24EB...0x24F4) {$c = chr($_); $s =~ s/$c/10 + $_ - 0x24EA/ge;} # 11 - 20
    for (0x3248...0x324F) {$c = chr($_); $s =~ s/$c/10 * ($_ - 0x3247)/ge;} # 10 20 30 ... 80

    for (0x1F150...0x1F169) {$c = chr($_); $s =~ s/$c/chr(0x40 + $_ - 0x1F14F)/ge;} # 10 20 30 ... 80

    return $s if Unicode::Normalize::checkNFKC($s);
    return Unicode::Normalize::NFKC($s);
    };
}
