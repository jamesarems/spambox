#line 1 "sub main::create_iprange_regexp"
package main; sub create_iprange_regexp {   ##no critic (ArgUnpacking)
   return _build_ip_regexp( \@_ );
}
