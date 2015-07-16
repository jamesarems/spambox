#line 1 "sub main::rdbm_RunSTM"
package main; sub rdbm_RunSTM {
    my ($self, $tag, $stm) = @_;
    my $sth;
    my $r;
    eval {
        $sth = $self->_prepare("$tag$self->{table}",$stm);
        $sth->execute();
        &main::mlog(0, "Database $tag statement failed (".$self->{table}."): $DBI::errstr") if $sth->err;
        $r = $sth->rows;
        $sth->finish;
    };
    &main::mlog(0, "error: $tag: $@ - $DBI::errstr") if $@ && $main::DataBaseDebug;
    eval{$self->commit} unless $main::DBautocommit;
    threads->yield();
    return $r;
}
