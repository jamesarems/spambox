#line 1 "sub main::clearDBCon"
package main; sub clearDBCon {
    &clearDBConPrivat();
    my %dbh;
    foreach my $dbGroup (@GroupList) {
        next unless $DBisUsed;
        next if $dbGroup eq 'AdminGroup' && $WorkerNumber != 0 && $WorkerNumber < 10000;
        foreach my $dbGroupEntry (@$dbGroup) {
            my ($KeyName,$dbConfig,$CacheObject,$realFileName,$mysqlFileName,$FailoverValue,$mysqlTable) = split(/,/o,$dbGroupEntry);
            if(defined $$CacheObject && ${$dbConfig} =~ /DB:/o) {
                eval{$$CacheObject->rdbm_cleanCache() if "$$CacheObject" =~ /Tie::RDBM/o;} if ! $WorkerNumber;
                $dbh{$$CacheObject->{'dbh'}} = 1 if eval{exists $$CacheObject->{'dbh'};};
                $dbh{$$CacheObject->{hashobj}->{'dbh'}} = 1 if eval{exists $$CacheObject->{hashobj}->{'dbh'};};
                undef $$CacheObject; # undef if we have switched from database to files
            }
            eval {untie %$KeyName if (${$dbConfig} =~ /DB:/o);}; # untie if we have switched from database to files
        }
    }
    eval{if ($_) {$_->disconnect();}} for keys %dbh;
}
