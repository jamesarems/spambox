#line 1 "sub main::cleanMIMEHeader2UTF8"
package main; sub cleanMIMEHeader2UTF8 {
    my ($m , $noconvert) = @_;
    my $msg = ref($m) ? $$m : $m;
    $msg =~ s/([^\x0D])\x0A/$1\x0D\x0A/go;
    my $hl = index($msg,"\x0D\x0A\x0D\x0A");
    if ($hl > 0) {
        $msg = substr($msg,0,$hl);
        $msg =~ s/[\x80-\xFF]/_/go;
        $msg = decodeMimeWords2UTF8($msg) if ! $noconvert;
        $msg .= "\x0D\x0A\x0D\x0A";
        return $msg;
    } elsif ($hl == 0) {
        return "\x0D\x0A\x0D\x0A";
    }
}
