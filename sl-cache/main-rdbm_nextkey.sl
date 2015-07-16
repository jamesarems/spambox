#line 1 "sub main::rdbm_nextkey"
package main; sub rdbm_nextkey {
    my ($self, $lastkey) = @_;
    # no statement handler defined, so nothing to iterate over
    my $sth;
    return unless ($sth = $self->{"fetchkeys$self->{table}"});
    my ($r,$key,$value);
    eval{
        $r = $sth->fetch();
        if (!$r) {
        	$sth->finish;
            delete $self->{"fetchkeys$self->{table}"};
            delete $self->{nextvalue};
            return;
        }
        ($key,$value) = ($r->[0], ($r->[2] ? thaw($r->[1]) : $r->[1]) );
        $self->{nextvalue}{$key} = $value if defined($key) && defined($value);  # cache the value for the next fetch
    };
    &main::mlog(0, "error: NEXTKEY (".$self->{table}."): $@ - $DBI::errstr") if $@ && $main::DataBaseDebug;
    threads->yield();
    return $key;
}
