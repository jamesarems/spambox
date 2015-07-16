#line 1 "sub main::RMabort"
package main; sub RMabort {mlog(0,"RMabort: $_[1] - report to ". $Con{$_[0]}->{to}); done2($_[0]);}
