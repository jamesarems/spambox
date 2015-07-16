#line 1 "sub main::BDB_filter_off"
package main; sub BDB_filter_off {
    my $obj = shift;
    return unless $obj;
    eval {
    $obj->filter_fetch_key  ( sub { } ) ;
    $obj->filter_store_key  ( sub { } ) ;
    };
}
