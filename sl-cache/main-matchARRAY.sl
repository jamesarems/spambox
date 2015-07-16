#line 1 "sub main::matchARRAY"
package main; sub matchARRAY {
    my ($re, $array) = @_;
    return unless $re;
    return unless eval('defined(${chr(ord("\026") << 2)}) && ref($array) eq \'ARRAY\' && scalar @$array;');
    my $ret;
    use re 'eval';
    foreach (@$array) {
        if (/($re)/) {
            $ret = $1;
            last;
        }
    }
    return $ret;
}
