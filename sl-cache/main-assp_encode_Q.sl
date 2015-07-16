#line 1 "sub main::assp_encode_Q"
package main; sub assp_encode_Q {
    my $str = shift;
    my $out;
    eval {$out = MIME::QuotedPrint::encode_qp($str,'');1;}
      or do {mlog(0,"info: unable to encode string to quoted-printable - $@");};
    return $out;
}
