#line 1 "sub main::getHashName"
package main; sub getHashName {
    my ($confname, $file) = @_;
    my $subname;
    $confname = 'ldaplistdb' if $confname eq 'LDAPShowDB';
    if ($confname eq 'DelayShowDB' or $confname eq 'delaydb') {
        $subname = 'Delay';
        $confname = 'delaydb';
    }
    if ($confname eq 'DelayShowDBwhite') {
        $subname = 'DelayWhite';
        $confname = 'delaydb';
    }
    if ($confname eq 'spamdb') {
        $subname = 'Spamdb';
        $confname = 'spamdb';
    }
    if ($confname eq 'ShowHeloBlack') {
        $subname = 'HeloBlack';
        $confname = 'spamdb';
    }
    if ($confname) {
        my $found = 0;
        foreach my $dbGroup (@GroupList) {
            next if $dbGroup eq 'AdminGroup';
            foreach my $dbGroupEntry (@$dbGroup) {
                my ($KeyName,$dbConfig,$CacheObject,$realFileName,$mysqlFileName,$FailoverValue,$mysqlTable) = split(/,/o,$dbGroupEntry);
                $found = 1 if ($dbConfig eq $confname && (! $subname || $subname eq $KeyName));
                next if $dbConfig eq 'pbdb';
                next if $$dbConfig !~ /DB:/o;
                return $KeyName if ($dbConfig eq $confname && (! $subname || $subname eq $KeyName));
            }
        }
        return $confname if ! $found;
        return;
    } elsif ($file) {
        foreach my $dbGroup (@GroupList) {
            next if $dbGroup eq 'AdminGroup';
            foreach my $dbGroupEntry (@$dbGroup) {
                my ($KeyName,$dbConfig,$CacheObject,$realFileName,$mysqlFileName,$FailoverValue,$mysqlTable) = split(/,/o,$dbGroupEntry);
                next if $realFileName !~ /DB:/o;
                my $f1 = $realFileName;
                $f1 =~ s/DB:/$FailoverValue/o;
                return $KeyName if $f1 eq $file;
            }
        }
    }
    return;
}
