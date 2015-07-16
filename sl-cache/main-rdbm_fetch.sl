#line 1 "sub main::rdbm_fetch"
package main; sub rdbm_fetch {
    my($self,$key) = @_;
    return unless defined $key;
    return delete $self->{nextvalue}{$key} if (exists $self->{nextvalue}{$key}); # satisfy an each loop
    %{$self->{nextvalue}} = ();
    if ($main::DBCacheMaxAge && $main::DBCacheSize && ! $self->{noRDBMcache} && exists $self->{tableID}) {
        my $time = Time::HiRes::time;
        threads->yield;
        my $c = \@{'main::'.lc $self->{table}};  # store the cache in $c->
        threads->yield;
        for (my $i = 0; $i < $main::DBCacheSize * 4; $i+=4) {
            return $c->[$i+2] if $c->[$i+1] eq $key && $c->[$i+3];
        }
    }
    my $sth; my $result; my $cols;
    eval {
        $cols = $self->{'canfreeze'} ? "$self->{'value'},$self->{'frozen'}" : $self->{'value'};
        $sth = $self->_run_query("fetch$self->{table}",<<END,$key);
SELECT $cols FROM $self->{table} WHERE $self->{key}=?
END
        $result = $sth->fetchrow_arrayref();
        $sth->finish;
    };
    &main::mlog(0, "error: Fetch (".$self->{table}."): $@ - $DBI::errstr") if $@ && $main::DataBaseDebug;
    threads->yield();
    if ($result && $main::DBCacheMaxAge) {
        my $value = $self->{'canfreeze'} && $result->[1] ? thaw($result->[0]) : $result->[0];
        &main::rdbm_updateCache($self, $key, $value, 2);
    } else {
        return unless $result;
    }
    return $self->{'canfreeze'} && $result->[1] ? thaw($result->[0]) : $result->[0];
}
