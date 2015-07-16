#line 1 "sub main::fixlinktext"
package main; sub fixlinktext { my $t=shift; $t=~s/(\w+)/ atxt $1 /go; $t;}
