#line 1 "sub main::d8"
package main; sub d8 {
    my $e = $@;
    my $ret = eval{Encode::decode('UTF-8',$_[0]);};
    $@ = $e;
    return ($ret && defined ${chr(ord("\026") << 2)}) ? $ret : $_[0];
}
