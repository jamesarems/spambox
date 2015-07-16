#line 1 "sub main::rdbm_updateCache"
package main; sub rdbm_updateCache {
    my ($self, $key, $value, $changed) = @_;
    return if ! $main::DBCacheMaxAge || ! $main::DBCacheSize || $main::checkdb || $self->{noRDBMcache} || ! exists $self->{tableID};
    my $time = Time::HiRes::time;
    threads->yield();
    my $c = \@{'main::'.lc $self->{table}};
    threads->yield();
    my ($tmax,$rmax) = (0,0); my $i = 0;
    for ($i = 0; $i < ($main::DBCacheSize * 4); $i+=4) {
        last if $c->[$i+1] eq $key;
        last if ! defined $c->[$i];
        if ($c->[$i] > $tmax) {$tmax = $c->[$i]; $rmax = $i;}
    }
    my $overwrite;
    if ($i >= ($main::DBCacheSize * 4)) {
        $i = $rmax;
        $overwrite = 1;
    }
    if ($overwrite && $c->[$i+3]) {
        $main::checkdb = 1;
        $c->[$i+3] = undef;
        defined $c->[$i+2] ? $self->STORE($c->[$i+1],$c->[$i+2]) : $self->DELETE($c->[$i+1]);
        $main::checkdb = undef;
    }
    ($c->[$i],$c->[$i+1],$c->[$i+2],$c->[$i+3]) = ($time,$key,$value,($changed || $c->[$i+3]));
    threads->yield();
}
