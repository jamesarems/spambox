#line 1 "sub main::spambox_encode_B"
package main; sub spambox_encode_B {
    my $str = shift;
    my $out;
    eval {$out = MIME::Base64::encode_base64($str, '');1;}
      or do {mlog(0,"warning: unable to encode string to base64 - $@");};
    return $out;
}