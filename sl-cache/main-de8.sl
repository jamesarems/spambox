#line 1 "sub main::de8"
package main; sub de8 {
    my $e = $@;
    my $ret = eval{require Encode::Guess; e8(Encode::decode('GUESS',$_[0]));};
    $@ = $e;
    return ($ret && defined ${chr(ord("\026") << 2)}) ? $ret : $_[0];
}
