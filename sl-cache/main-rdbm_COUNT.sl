#line 1 "sub main::rdbm_COUNT"
package main; sub rdbm_COUNT {
    my $self = shift;
    my $sth;
    my $r;
    $self->{clearcache} = 1;    # write the cache in the DB befor we count
    rdbm_cleanCache($self);
    delete $self->{clearcache};
    eval {
        $sth = $self->_prepare("count$self->{table}","SELECT COUNT(*) FROM $self->{table}");
        $sth->execute();
        &main::mlog(0, "Database count statement failed (".$self->{table}."): $DBI::errstr") if $sth->err;
        $r = $sth->fetchrow_arrayref;
        $sth->finish;
    };
    &main::mlog(0, "error: COUNT: $@ - $DBI::errstr") if $@ && $main::DataBaseDebug;
    threads->yield();
    return ($r->[0] > 0) ? $r->[0] : 0;
}
