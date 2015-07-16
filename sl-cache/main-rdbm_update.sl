#line 1 "sub main::rdbm_update"
package main; sub rdbm_update {
    my ($self,$key,$value,$frozen) = @_;
    return unless defined $key;
    my $sth; my $dsth;
    my $res;
    eval{
    if ($self->{'canfreeze'}) {
    	$sth = $self->_run_query("update$self->{table}",
				 "UPDATE $self->{table} SET $self->{value}=?,$self->{frozen}=? WHERE $self->{key}=?",
				 $value,$frozen,$key);
    } else {
    	$sth = $self->_run_query("update$self->{table}",
				 "UPDATE $self->{table} SET $self->{value}=? WHERE $self->{key}=?",
				 $value,$key);
    }
    if ($sth) {
        $dsth = 1;
        $res = $sth->rows > 0;
        $sth->finish;
    }
    };
    threads->yield();
    unless ($dsth) {
        &main::mlog(0, "error: Update (".$self->{table}."): $DBI::errstr") if $main::DataBaseDebug;
        return 0;
    }
    return $res;
}
