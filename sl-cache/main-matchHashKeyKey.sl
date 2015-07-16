#line 1 "sub main::matchHashKeyKey"
package main; sub matchHashKeyKey {
    my ($hash, $key, $wantkey) = @_;
    $wantkey ||= 1;
    return matchHashKey($hash, $key, $wantkey);
}
