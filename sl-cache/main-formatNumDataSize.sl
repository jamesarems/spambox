#line 1 "sub main::formatNumDataSize"
package main; sub formatNumDataSize {
    my $size = shift;
    my $res;
    if ($size >= 1099511627776) {
        $res = sprintf("%.2f TByte", $size / 1099511627776);
    } elsif ($size >= 1073741824) {
        $res = sprintf("%.2f GByte", $size / 1073741824);
    } elsif ($size >= 1048576) {
        $res = sprintf("%.2f MByte", $size / 1048576);
    } elsif ($size >= 1024) {
        $res = sprintf("%.2f kByte", $size / 1024);
    } else {
        $res = $size . ' Byte';
    }
    return $res;
}
