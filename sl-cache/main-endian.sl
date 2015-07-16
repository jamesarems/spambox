#line 1 "sub main::endian"
package main; sub endian {
    my ($str,$enc) = @_;
    my $is32 = $enc =~ /^(?:UTF[_-]?32|UCS[_-]?4)$/oi;
    return '' if $is32 && $$str =~ /^(?:\x00\x00\xFE\xFF|\xFF\xFE\x00\x00)/o; # UTF-32 UCS-4 BOM available
    return '' if ! $is32 && $$str =~ /^(?:\xFE\xFF|\xFF\xFE)/o; # UTF-16 UCS-2 BOM available
    my $sp = ($is32)
             ? '^(?:[\x00-\xff]{4})*?\x00\x00\x00[\x20-\x7F]'   # any 4 byte*? + ASCII (U+00000020 ... U+0000007F)
             : '^(?:[\x00-\xff]{2})*?\x00[\x20-\x7F]';          # any 2 byte*? + ASCII (U+0020 ... U+007F)
    return ($$str =~ /$sp/) ? 'LE' : 'BE'; # look for a space and return the endianess string LE or BE
}
