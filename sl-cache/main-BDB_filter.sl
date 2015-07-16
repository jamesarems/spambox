#line 1 "sub main::BDB_filter"
package main; sub BDB_filter {
    my $obj = shift;
    return unless $obj;
    eval{
    $obj->filter_fetch_key  ( sub { threads->yield(); } ) ;
    $obj->filter_store_key  ( sub { threads->yield(); } ) ;
    };
}
