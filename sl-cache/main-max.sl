#line 1 "sub main::max"
package main; sub max {
    return [sort {$main::b <=> $main::a} @_]->[0];
}
