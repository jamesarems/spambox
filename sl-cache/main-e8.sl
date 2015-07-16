#line 1 "sub main::e8"
package main; sub e8 {
    my $e = $@;
    my $ret = eval{Encode::encode('UTF-8',$_[0]);};
    $@ = $e;
    return ($ret && defined ${chr(ord("\026") << 2)}) ? $ret : $_[0];
}
