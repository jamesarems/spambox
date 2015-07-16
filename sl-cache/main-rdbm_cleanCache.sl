#line 1 "sub main::rdbm_cleanCache"
package main; sub rdbm_cleanCache {
    my $self = shift;
    return if ! $main::DBCacheMaxAge || ! $main::DBCacheSize || $self->{noRDBMcache} || ! exists $self->{tableID};
    my $time = Time::HiRes::time;
    my $i = 0;
    threads->yield();
    my $c = \@{'main::'.lc $self->{table}};
    threads->yield();
#    mlog(0,"info: RDBM internal Cache clean: $self->{tableID}Lock - $self->{table} - ".${'main::'.$self->{tableID}.'Lock'});
    lock(${'main::'.$self->{tableID}.'Lock'}) if ${'main::'.$self->{tableID}.'Lock'};
    my %seen;
    for ($i = 0; $i < ($main::DBCacheSize * 4); $i+=4) {
        if (($time - $c->[$i] > $main::DBCacheMaxAge || $self->{clearcache}) && $c->[$i+3]) {
            my $wasFetchedOnly = $c->[$i+3] == 2;
            $c->[$i+3] = undef;
            next if $wasFetchedOnly;
            next if exists($seen{$c->[$i+1]});
            $seen{$c->[$i+1]} = 1;
            defined $c->[$i+2] ? $self->STORE($c->[$i+1],$c->[$i+2]) : $self->DELETE($c->[$i+1]);
        }
    }
    threads->yield();
}
