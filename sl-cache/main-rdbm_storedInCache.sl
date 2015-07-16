#line 1 "sub main::rdbm_storedInCache"
package main; sub rdbm_storedInCache {
    my ($self, $key, $value) = @_;
    return if ! $main::DBCacheMaxAge || ! $main::DBCacheSize || $main::checkdb || $self->{noRDBMcache} || ! exists $self->{tableID};
    my $time = Time::HiRes::time;
    threads->yield();
    my $c = \@{'main::'.lc $self->{table}};
    threads->yield();
    my $i = 0;
    for ($i = 0; $i < ($main::DBCacheSize * 4); $i+=4) {
        if ($c->[$i+1] eq $key && $c->[$i+3]) {
            ($c->[$i],$c->[$i+2],$c->[$i+3]) = ($time,$value,1);
            threads->yield();
            return 1;
        }
    }
    return 0;
}
