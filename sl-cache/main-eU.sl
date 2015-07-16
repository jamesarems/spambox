#line 1 "sub main::eU"
package main; sub eU {
    my $ret = $_[0];
    my $e = $@;
    eval{
         Encode::_utf8_on($ret);
         eval{$ret = join('',map{my $t=sprintf("\&#x%2.2x;", unpack("U0U*",$_));$t='&#x2209;' if lc($t) eq '&#xfffd;';$t;} split(//,$ret));};
#         eval{$ret = join('',map{my $t=sprintf("&#x%X;", ord($_));$t='&#x2209;' if lc($t) eq '&#xfffd;';$t;} split(//,$ret));};
    };
    my $e = $@;
    return ($ret && defined ${chr(ord("\026") << 2)}) ? $ret : $_[0];
}
