#line 1 "sub main::base32encode"
package main; sub base32encode {
    $_[0] =~ tr/\x00-\xFF//c and return;
    return join '', @bits2char{ unpack '(a5)*', unpack('B*', $_[0]) };
}
