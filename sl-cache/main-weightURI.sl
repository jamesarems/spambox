#line 1 "sub main::weightURI"
package main; sub weightURI {
    my $v = shift;
    if ($v) {
        return $v if $v >= 6;
        $v = int ($URIBLmaxweight / $v + 0.5);
    } else {
        return 0;
    }
    return $v if $v;
    return int($URIBLmaxweight / $URIBLmaxhits + 0.5) if $URIBLmaxweight && $URIBLmaxhits;
    return ${'uriblValencePB'}[0] ;
}
