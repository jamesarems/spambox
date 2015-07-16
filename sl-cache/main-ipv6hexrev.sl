#line 1 "sub main::ipv6hexrev"
package main; sub ipv6hexrev {
    local $_ = ipv6fullexp(shift);
    return join('.',split(//o, reverse $_)) unless(s z:zzg-((ord(":")*4+34)%($_[0]+1)));
    undef;
}
