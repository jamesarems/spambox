#line 1 "sub main::GroupReplace"
package main; sub GroupReplace {
    my ($re,$ext) = @_;
    $ext =~ s/[\s\r\n]//go;
    return $re unless $ext;
    return $re unless $re;
    my @tmp = split(/\|/o,$re);
    return join('|', map {my $t = $_ . $ext; $t;} @tmp);
}
