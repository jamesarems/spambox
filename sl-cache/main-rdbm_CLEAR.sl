#line 1 "sub main::rdbm_CLEAR"
package main; sub rdbm_CLEAR {
    my $self = shift;
    my ($dbh, $sth, $error);
    $dbh = $self->{'dbh'};
    %{$self->{nextvalue}} = ();
    eval {
        $sth = $self->_prepare("truncate$self->{table}","TRUNCATE TABLE $self->{table}");
        $sth->execute();
        $sth->finish;
    } if $forceTrunc4ClearDB;
    eval {
        mlog(0, "Database TRUNCATE TABLE $self->{table} statement failed: $DBI::errstr - will try DELETE FROM $self->{table}") if $forceTrunc4ClearDB;
        $sth = $self->_prepare("clear$self->{table}","DELETE FROM $self->{table}");
        $sth->execute();
        $sth->finish;
    } if $@ || ! $forceTrunc4ClearDB;
    if (eval{$dbh->err;}) {
        $error = $DBI::errstr;
        mlog(0, "Database delete all statement failed (".$self->{table}."): $error");
        eval{$sth->finish;};
    }
    $@ = $error if $error;
    eval{$self->commit} unless $main::DBautocommit;
    threads->yield();
    @{'main::'.lc $self->{table}} = ();
    return 1;
}
