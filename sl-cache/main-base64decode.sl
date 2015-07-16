#line 1 "sub main::base64decode"
package main; sub base64decode {
    my $str = shift;
    my $res;
    $str =~ tr|A-Za-z0-9+/||cd;
    $str =~ tr|A-Za-z0-9+/| -_|;
    while ($str =~ /(.{1,60})/gso) {
        my $len = chr(32 + length($1)*3/4);
        $res .= unpack("u", $len . $1 );
    }
    $res;
}
