#line 1 "sub main::BDB_CLEAR"
package main; sub BDB_CLEAR {
    my $self = shift;
    threads->yield();
    my $lock;
    $lock = $self->cds_lock() if $main::lockBDB && $self->cds_enabled();
    $self->truncate(my $cnt);
}
