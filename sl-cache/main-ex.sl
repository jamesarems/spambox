#line 1 "sub main::ex"
package main; sub ex {
    my($s,$l) = @_;
    $l ||= 2;
    $s ||= '00';
    return $s if length($s) == $l;
    $s = sprintf("%02d",$s);
    $s = '20'.$s if $l == 4;
    return $s;
}
