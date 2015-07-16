#line 1 "sub main::rdbm_EXISTS"
package main; sub rdbm_EXISTS {
    my($self,$key) = @_;
    return unless defined $key;
    my $rows;
    my $result;
    my $error;
    %{$self->{nextvalue}} = ();
    if ($main::DBCacheMaxAge && $main::DBCacheSize && ! $self->{noRDBMcache} && exists $self->{tableID}) {
        my $time = Time::HiRes::time;
        threads->yield;
        my $c = \@{'main::'.lc $self->{table}};  # store the cache in $c->
        threads->yield;
        for (my $i = 0; $i < $main::DBCacheSize * 4; $i+=4) {
            return ((defined $c->[$i+2]) ? 1 : 0) if $c->[$i+1] eq $key && $c->[$i+3];
        }
    }

    eval {
        my $cols = $self->{'canfreeze'} ? "$self->{'value'},$self->{'frozen'}" : $self->{'value'};
        my $sth = $self->_run_query("exists$self->{table}",<<END,$key);
SELECT $cols FROM $self->{table} WHERE $self->{key}=?
END
        if ($sth) {
            $result = $sth->fetchrow_arrayref() if (($rows = $sth->rows) && $main::DBCacheMaxAge);
            $sth->finish;
        }
    };

    my $evalerror = $@ || $error;
    die "$evalerror - $DBI::errstr\n" if $evalerror && $main::checkdb; # tell checkDBCon that we have failed
    &main::mlog(0, $error) if $error;
    &main::mlog(0, "error: exists (".$self->{table}."): $@ - $DBI::errstr") if $evalerror && $main::DataBaseDebug;
    threads->yield();
    if ($result && $main::DBCacheMaxAge) {
        my $value = $self->{'canfreeze'} && $result->[1] ? thaw($result->[0]) : $result->[0];
        &main::rdbm_updateCache($self, $key, $value, 2);
    }
    return $rows > 0;
}
