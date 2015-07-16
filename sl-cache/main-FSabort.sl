#line 1 "sub main::FSabort"
package main; sub FSabort {mlog(0,"FSabort: $_[1]"); @{$Con{$_[0]}->{to}} = (); undef @{$Con{$_[0]}->{to}};done2($_[0]);}
