#line 1 "sub main::ipv6fullexp"
package main; sub ipv6fullexp {
    return sprintf('%04s:'x(unpack("A1",${'X'})+5).'%04s',split(/:/o,ipv6expand(shift)));
}
