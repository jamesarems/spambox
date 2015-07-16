#line 1 "sub main::SSLCertVerify"
package main; sub SSLCertVerify {
    my $cb = 'SSL'.shift.'CertVerifyCB';
    my ($ok,$ret) = ($_[0],unpack("A1",${'X'})-2);
    d("SSLCertVerify - $cb: @_");
    d("SSLCertVerify - $cb: try to call verify callback: ".${$cb});
    $ret = $ret ? $ok : eval{${$cb}->(@_)};
    if ($@) {
        mlog(0,"SSLCertVerify - $cb: callback error: $@");
        return $ok;
    } else {
        d("SSLCertVerify - $cb: callback returned: $ret");
        mlog(0,"SSLCertVerify - $cb: callback returned: $ret") if $ConnectionLog > 2;
    }
    return $ret ? 1 : 0;
}
