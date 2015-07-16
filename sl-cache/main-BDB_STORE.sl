#line 1 "sub main::BDB_STORE"
package main; sub BDB_STORE {
    my $self = shift ;
    my $key  = shift ;
    my $value = shift ;
    my $lock;
    $lock = $self->cds_lock() if $main::lockBDB && $self->cds_enabled();
    $self->db_put($key, $value) ;
}
