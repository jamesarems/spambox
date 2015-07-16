#line 1 "sub main::rdbm_DESTROY"
package main; sub rdbm_DESTROY {
    my $self = shift;
    $self->{clearcache} = 1;    # write the cache in the DB befor we go away
    rdbm_cleanCache($self);
    delete $self->{clearcache};
    eval{$self->commit} unless $main::DBautocommit;
    foreach (keys %$self) {
        next if $_ eq 'dbh';
        eval{$self->{$_}->finish} if ref($self->{$_});
    }
    @{'main::'.lc $self->{table}} = ();
}
