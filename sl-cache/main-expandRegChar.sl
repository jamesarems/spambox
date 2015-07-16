#line 1 "sub main::expandRegChar"
package main; sub expandRegChar {
    my $char = shift;
    my $ucd = ord(uc($char));
    my $lcd = ord(lc($char));
    my $uch = sprintf "%x", $ucd;
    my $lch = sprintf "%x", $lcd;
       $ucd < 99 and $ucd = '0?' . $ucd;
       $lcd < 99 and $lcd = '0?' . $lcd;
    my $esc = ($char =~ /[a-zA-Z0-9]/) ? '' : '\\';
    my $hex = ($uch eq $lch) ? $uch : "$uch|$lch";
    my $dec = ($ucd eq $lcd) ? $ucd : "$ucd|$lcd" ;
    return '(?i:[\=\%](?i:' . $hex . ')|\&\#(?:' . $dec . ')\;?|' . "$esc$char)(?:\\=(?:\\015?\\012|\\015))?";
}
