#line 1 "sub main::rdbm_firstkey"
package main; sub rdbm_firstkey {
    my $self = shift;

    my $r; my $error;

    $self->{clearcache} = 1;    # write the cache in the DB befor we iterate it
    rdbm_cleanCache($self);
    delete $self->{clearcache};
    
    eval {
    if ($self->{"fetchkeys$self->{table}"}) {
        eval{$self->{"fetchkeys$self->{table}"}->finish();};  # to prevent truncation in ODBC driver
        delete $self->{"fetchkeys$self->{table}"};
    }
    my $sth = $self->_prepare("fetchkeys$self->{table}",$self->{'canfreeze'} ? <<END1 : <<END2);
select $self->{'key'},$self->{'value'},$self->{'frozen'} from $self->{table}
END1
select $self->{'key'},$self->{'value'} from $self->{table}
END2
    if ($sth) {
        $sth->execute() || ($error = "error: FIRSTKEY (".$self->{table}."): Can't execute select statement: $DBI::errstr");
        $r = $sth->fetch();
        my $value = ($r->[2] ? thaw($r->[1]) : $r->[1]);
        $self->{nextvalue}{$r->[0]} = $value if defined($value) && defined $r->[0];  # cache the value for the next fetch
    } else {
        $error = "error: FIRSTKEY: Can't get value from select statement (".$self->{table}."): $DBI::errstr";
        delete $self->{"fetchkeys$self->{table}"};
    }
    };
    &main::mlog(0, $error) if $error;
    &main::mlog(0, "error: FIRSTKEY (".$self->{table}."): $@ - $DBI::errstr") if $@ && $main::DataBaseDebug;
    threads->yield();
    return defined($r) ? $r->[0] : undef;
}
