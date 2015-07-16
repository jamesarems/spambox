#line 1 "sub main::decHTMLentHD"
package main; sub decHTMLentHD {
    my ($s, $how) = @_;
    eval('
    if (defined *{\'yield\'}) {
    $s = chr(($how eq \'hex\')?hex($s):($how eq \'oct\')?oct($s):$s);
    use bytes;
    $s =~ s/^(?:\xA1[\x43\x44\x4F]|\xE3\x80\x82|\xEF(?:\xBC\x8E|\xB9\x92)|\xDB\x94)$/./go;  #Big5 Chinese language character set (.)
    $s =~ s/^\xA0$/ /gosi;  # decode to space not to \160
    $s =~ s/^\xAD$/-/gosi;  # decode to - not to \173
    } no bytes;');
    return $s;
}
