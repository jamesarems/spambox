#line 1 "sub main::initFileHashes"
package main; sub initFileHashes {
    my $singleGroup = shift;
    foreach my $dbGroup (@GroupList) {
        next if $dbGroup eq 'AdminGroup' && $WorkerNumber != 0 && $WorkerNumber < 10000;
        next if $singleGroup && $singleGroup ne $dbGroup;
        foreach my $dbGroupEntry (@$dbGroup) {
            my ($KeyName,$dbConfig,$CacheObject,$realFileName,$mysqlFileName,$FailoverValue,$mysqlTable) = split(/,/o,$dbGroupEntry);
            if ((! $CanUseTieRDBM && ! $CanUseBerkeleyDB) || ${$dbConfig} !~ /DB:/o || $failedTable{$KeyName} == 1) {
                if (! $calledfromThread) {
                    next if (is_shared(%$KeyName));
                    if ($dbGroup ne 'AdminGroup') {
                        if ($dbGroup ne 'spamdbGroup' || ($dbGroup eq 'spamdbGroup' && ! $HMM4ISP)) {
                            share(%$KeyName);
                        }
                    }
                    if ($failedTable{$KeyName} == 2) {
                        mlog(0,"warning : setting configvalue for $dbConfig to $FailoverValue");
                        ${$dbConfig} = $FailoverValue;
                        $realFileName =~ s/DB:/$FailoverValue/o;
                    }
                    if ($dbGroup ne 'AdminGroup') {
                        &LoadHash($KeyName, "$base/$realFileName", 0) if (${$dbConfig} && ${$dbConfig} !~ /DB:/o);
                        $$CacheObject = 1;
                    } else {
                        if ($singleGroup eq 'AdminGroup'){
                            eval{
                                my $cmd = "'orderedtie',\"$base/$realFileName\"" ;
                                $$CacheObject=tie %$KeyName,'SPAMBOX::CryptTie',$adminusersdbpass,0,$cmd;
                            } if (${$dbConfig} && ${$dbConfig} !~ /DB:/o);
                            if ($@) {
                                mlog(0,"warning: unable init AdminUsersDB - only root will have access to the GUI");
                            } else {
                                mlog(0,"info: $dbConfig ($base/$realFileName) - loaded") if $$CacheObject;
                            }
                        }
                    }
                }
                $failedTable{$KeyName} = 1;
            }
        }
    }
}
