#line 1 "sub main::erw"
package main; sub erw {
    my ($word,$quant) = @_;
    my $ret;
    $ret = '(?:' if $quant;
    $ret .= join('', map {&expandRegChar($_)} split(//o,$word));
    $ret .= ")$quant" if $quant;
    return $ret;
}
