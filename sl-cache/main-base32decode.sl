#line 1 "sub main::base32decode"
package main; sub base32decode {
    $_[0] =~ tr/a-zA-Z2-7//c and return;
	my $str = join '', @char2bits[ unpack 'C*', $_[0] ];
    my $padding = length($str) % 8;
    $padding < 5 or return;
    $str =~ s/0{$padding}\z// or return;
    return pack('B*', $str);
}
