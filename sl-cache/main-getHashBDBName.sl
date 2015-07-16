#line 1 "sub main::getHashBDBName"
package main; sub getHashBDBName {
    my ($hash) = shift;
    if ($hash eq 'Griplist' && $griplist) {
        return $griplist;
    }
    if ($hash =~ /^HMM/o && $runHMMusesBDB) {
        return $hash;
    }
    foreach my $dbGroup (@GroupList) {
        foreach my $dbGroupEntry (@$dbGroup) {
            my ($KeyName,$dbConfig,$CacheObject,$realFileName,$mysqlFileName,$FailoverValue,$mysqlTable) = split(/,/o,$dbGroupEntry);
            next if $realFileName !~ /DB:/o;
            my $f1 = $realFileName;
            $f1 =~ s/DB:/$FailoverValue/o;
            return $f1 if $KeyName eq $hash;
        }
    }
    return;
}
