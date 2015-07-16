#line 1 "sub main::rdbm_delete"
package main; sub rdbm_delete {
    my($self,$key) = @_;
    return 1 unless defined $key;
    my $stm = "DELETE FROM $self->{table} WHERE $self->{key}=?";
    my $tag = "delete$self->{table}";
    my $row = 0;
    my $okey = $key;
    %{$self->{nextvalue}} = ();
    if ($main::DoSQL_LIKE && $key =~ /\*/o) {
        $okey = undef;
        $self->{clearcache} = 1;    # write the cache in the DB befor we delete a bulk
        rdbm_cleanCache($self);
        delete $self->{clearcache};
        my $escape;
        my $echar;
        if ($key =~ /[_%]/o) {
            $echar = ($key=~/!/o) ? (($key=~/#/o ? '§' : '#') ) : '!';
            $key =~ s/([_%])/$echar$1/go;
            $escape = " ESCAPE '$echar'";
        }
        my $stmLIKE = "DELETE FROM $self->{table} WHERE $self->{key} LIKE ?$escape";
        $stm = $stmLIKE if $key =~ s/\*/\%/gos;
        if ($stm eq $stmLIKE) {
           $tag = $escape ? "deletelike$echar$self->{table}" : "deletelike$self->{table}";
        }
        @{'main::'.lc $self->{table}} = ();
    } elsif ($main::DBCacheMaxAge && $main::DBCacheSize && ! $main::checkdb && ! $self->{noRDBMcache} && exists $self->{tableID}) {
        my $time = Time::HiRes::time;
        threads->yield;
        my $c = \@{'main::'.lc $self->{table}};  # store the cache in $c->
        threads->yield;
        for (my $i = 0; $i < $main::DBCacheSize * 4; $i+=4) {
            if ($c->[$i+1] eq $key && $c->[$i+3]) {
                 my $r = $c->[$i+2];
                 ($c->[$i],$c->[$i+2],$c->[$i+3]) = ($time,undef,1);
                 return defined $r;
            }
        }
    }
    my $error;
    eval {
    my $sth = $self->_run_query($tag,$stm,$key);
    $error = "Database delete statement failed (".$self->{table}."): $DBI::errstr" if $sth->err;
    $row = $sth->rows;
    $sth->finish;
    };
    &main::mlog(0, $error) if $error;
    &main::mlog(0, "error: delete (".$self->{table}."): $@ - $DBI::errstr") if $@ && $main::DataBaseDebug;
    eval{$self->commit} unless $main::DBautocommit;
    threads->yield();
    if ($okey && $row && $main::DBCacheMaxAge) {
        &main::rdbm_updateCache($self, $okey, undef, 1);
    }
    return $row;  # attention: it may possible that we return values above 1, if a sql like statement was executed and more than one
}                 # record was deleted
