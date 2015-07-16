#line 1 "sub main::initDBHashes"
package main; sub initDBHashes {

# generate the CacheObjects and Hashes for all Groups in GroupList, defined in the table above
# if there is "DB:" defined in $dbConfig, database tables are used - otherwise files are used
    return unless $DBisUsed;
    my $waserror = 0;
    my $switch_to_files = 0;
    my $dbh;
    do {
        $switch_to_files = 0 if ($switch_to_files);  #reset to normal state if we have switched over to files
        foreach my $dbGroup (@GroupList) {
            last if ($switch_to_files);
#            next if ($WorkerNumber == 10001 && $dbGroup =~ /delayGroup|LDAPGroup|AdminGroup/io);
            next if $dbGroup eq 'AdminGroup' && $WorkerNumber != 0 && $WorkerNumber < 10000;
            foreach my $dbGroupEntry (@$dbGroup) {
                last if ($switch_to_files);
                my ($KeyName,$dbConfig,$CacheObject,$realFileName,$mysqlFileName,$FailoverValue,$mysqlTable) = split(/,/o,$dbGroupEntry);
                undef $$CacheObject if(defined $$CacheObject && ${$dbConfig} =~ /DB:/o); # undef if we have switched from database to files
                eval {untie %$KeyName if (${$dbConfig} =~ /DB:/o);}; # untie if we have switched from database to files
                if (($CanUseTieRDBM or $CanUseBerkeleyDB) && ${$dbConfig} =~ /DB:/o && ! $waserror) {
                    eval {
                        if ( $DBusedDriver eq 'BerkeleyDB' && $CanUseBerkeleyDB)
                        {
                            my $BerkeleyFile = $realFileName;
                            $BerkeleyFile =~ s/DB:/$FailoverValue/o;
                            $BerkeleyFile = "$base/$BerkeleyFile.bdb";
                            d("BDB-ENV - $KeyName , $BerkeleyFile");
                            our %env = initBDBEnv($KeyName,$BerkeleyFile);
                            if ($dbGroup ne 'AdminGroup') {
                                d("BDB-DB (initDBHashes) - $KeyName , $BerkeleyFile");
                                $$CacheObject=tie %$KeyName, 'BerkeleyDB::Hash' , -Filename => $BerkeleyFile, %env;
                                BDB_filter($$CacheObject);
                            } else {
                                my $cmd = "'BerkeleyDB::Hash',-Filename => \"$BerkeleyFile\", \%main::env";
                                my $bin = $adminusersdbNoBIN ? 0 : 1 ;
                                d("BDB-DB (initDBHashes) - $KeyName , $BerkeleyFile");
                                $$CacheObject=tie %$KeyName,'ASSP::CryptTie',$adminusersdbpass,$bin,$cmd;
                            }
                            BDB_getRecordCount($KeyName);
                            &BDB_compact_hash($KeyName, 1000000) if $WorkerNumber == 0;
                        } elsif ( $DBusedDriver eq 'BerkeleyDB') {
                            die "DBdriver is set to 'BerkeleyDB' - but the module BerkeleyDB is not installed or disabled\n";
                        } else {
                            $dbh ||= DBI->connect("DBI:$DBusedDriver:".($mydb ? "database=$mydb;" : '').($myhost ? "$DBhostTag=$myhost" : '' )."$DBOption", $myuser, $mypassword,
                                                    { PrintError=>0,
                                    			      ChopBlanks=>1,
                                    			      Warn=>0 }
                                    			  );
                            if ($dbGroup ne 'AdminGroup') {
                                d("DB (initDBHashes) - $KeyName");
                                $$CacheObject=tie %$KeyName,'Tie::RDBM',{db=>$dbh,table=>"$mysqlTable",create=>1,DEBUG=>$DataBaseDebug};
                                $$CacheObject->{tableID} = $KeyName;
                            } else {
                                my $cmd = "'Tie::RDBM',\{db=>\$dbh,table=>\"$mysqlTable\",create=>1,DEBUG=>$DataBaseDebug\}";
                                my $bin = $adminusersdbNoBIN ? 0 : 1 ;
                                d("DB (initDBHashes) - $KeyName");
                                $$CacheObject=tie %$KeyName,'ASSP::CryptTie',$adminusersdbpass,$bin,$cmd,$dbh;
                            }
                        }
                    };
                    if($@) {    # there was an error tie
                        $failedTable{$KeyName} = 2;
                        if ($dbGroup ne 'AdminGroup') {
                            mlog(0,"$mysqlFileName database error: $@");
                            if (! $calledfromThread) {
                                $DBisUsed = 0;
                                $CanUseTieRDBM=0;
                                mlog(0,"Warning: can not use defined database - switching over to use files instead of database $mydb!");
                            }
                            $switch_to_files = 1;
                            $waserror = 1;
                        }
                    } else {
                        if (! $calledfromThread) {
                            CheckTableStructure($mysqlTable) if ($DBusedDriver eq 'mysql'); # change the table if there was made an upgrade
                            importDB($KeyName,$mysqlFileName,$mysqlTable,'','','');
                            $realFileName =~ s/DB:/$FailoverValue/o;
                            if ($DBusedDriver eq 'BerkeleyDB' && $CanUseBerkeleyDB) {
                                mlog(0,"using $DBusedDriver Database $base/$realFileName.bdb instead of file $base/$realFileName");
                            } else {
                                my $tbn = "<$mysqlTable>" . ' ' x (15 - length($mysqlTable));
                                mlog(0,"using table $tbn in $DBusedDriver Database <$mydb> instead of file $base/$realFileName");
                            }
                        }
                        $failedTable{$KeyName} = 0;
                    }
                } elsif ($waserror) {
                    $failedTable{$KeyName} = 2;
                }
            }
        }
    } while ($switch_to_files);
    if ($waserror && ! $calledfromThread) {
        mlog(0,"error : DB-failover loading hashes from files");
        &initFileHashes();
    }
}
