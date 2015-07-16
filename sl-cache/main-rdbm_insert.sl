#line 1 "sub main::rdbm_insert"
package main; sub rdbm_insert {
    my ($self,$key,$value,$frozen) = @_;
    return unless defined $key;
    my $sth;
    my $res;
    eval {
    if ($self->{'canfreeze'}) {
    	$sth = $self->_run_query("insert$self->{table}",
				 "INSERT INTO $self->{table} ($self->{key},$self->{value},$self->{frozen}) VALUES(?,?,?)",
				 $key,$value,$frozen);
    } else {
    	$sth = $self->_run_query("insert$self->{table}",
				 "INSERT INTO $self->{table} ($self->{key},$self->{value}) VALUES (?,?)",
				 $key,$value);
    }
    $res = ($sth && $sth->rows);
    $sth->finish if $sth;
    };
    threads->yield();
    return $res || ($main::DataBaseDebug && ! &main::mlog(0, "error: Insert (".$self->{table}."): $DBI::errstr"));
}
