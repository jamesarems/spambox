#line 1 "sub main::min"
package main; sub min {
    return [sort {$main::a <=> $main::b} @_]->[0];
}
