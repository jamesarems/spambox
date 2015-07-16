#line 1 "sub main::BDB_DELETE"
package main; sub BDB_DELETE {
    my $self = shift ;
    my $key  = shift ;
    my $lock;
    $lock = $self->cds_lock() if $main::lockBDB && $self->cds_enabled();
    $self->db_del($key) ;
}
