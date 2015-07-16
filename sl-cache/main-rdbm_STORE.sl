#line 1 "sub main::rdbm_STORE"
package main; sub rdbm_STORE {
    my($self,$key,$value) = @_;

    return unless defined $key;
    %{$self->{nextvalue}} = ();
    my $frozen = 0;
    my $res = 0;
    if (ref($value) && $self->{'canfreeze'}) {
	    $frozen++;
	    $value = nfreeze($value);
    }
    return 1 if &main::rdbm_storedInCache($self, $key, $value);
    eval {
        $res = $self->_update($key,$value,$frozen) || $self->_insert($key,$value,$frozen);
        $self->commit unless $main::DBautocommit;
    };
    if ($@) {
        $self->rollback unless $main::DBautocommit;
        &main::mlog(0, "error: STORE (".$self->{table}."): $@ - $DBI::errstr") if $@;
    }
    if ($res && $main::DBCacheMaxAge) {
        &main::rdbm_updateCache($self, $key, $value, 1);
    }
    return $res;
}
