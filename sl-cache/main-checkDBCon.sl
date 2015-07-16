#line 1 "sub main::checkDBCon"
package main; sub checkDBCon {
  my $nextcheck = shift;
  if ($nextcheck) {
      $nextDBcheck = $nextcheck;
  } else {
      return 0 if $nextDBcheck > time;
      if ($WorkerNumber == 0 or $WorkerNumber >= 10000) {
          $nextDBcheck = time + $ThreadsWakeUpInterval + 2;
      } else {
          $nextDBcheck = time + 90;
      }
  }
  my $cdberror=0;
  if ($DBusedDriver eq 'BerkeleyDB' && $CanUseBerkeleyDB) {
      return 0;
  }
  &sigoffTry(__LINE__);
  d('checkdbcon');
  $checkdb = 1;   # signal rdbm_EXISTS that it should die on errors
  my $dbh;
  foreach my $dbGroup (@GroupList) {
#      next if ($WorkerNumber == 10001 && $dbGroup =~ /delayGroup|LDAPGroup|AdminGroup/io);
      next if $dbGroup eq 'AdminGroup' && $WorkerNumber != 0 && $WorkerNumber < 10000 ;
      foreach my $dbGroupEntry (@$dbGroup) {
        my ($KeyName,$dbConfig,$CacheObject,$realFileName,$mysqlFileName,$FailoverValue,$mysqlTable) = split(/,/o,$dbGroupEntry);
        next if $KeyName =~ /HMM/o && $lockHMM;
        next if $KeyName eq 'Spamdb' && $lockBayes;
        if (${$dbConfig} =~ /DB:/o) {
          my $querystr="01AA01" . $KeyName .int(rand(10000)). "01AA01";
          d("chkdb - $KeyName");
          eval {exists ${$KeyName}{$querystr};
                d("chkdb - OK for $KeyName");
#                mlog(0,"info: checkdbcon OK for $KeyName") if ($WorkerNumber == 10000 && $MaintenanceLog > 2);
#                my $t; $t = lc $$CacheObject->{table} if "$$CacheObject" =~ /Tie::RDBM/oi;
#                mlog(0,"info: table-Cache: $$CacheObject->{table}: @{$t}") if ($WorkerNumber == 10000  && "$$CacheObject" =~ /Tie::RDBM/oi);
                delete $$CacheObject->{'cached_value'} if "$$CacheObject" =~ /Tie::RDBM/oi;
                delete $$CacheObject->{hashobj}->{'cached_value'}
                  if "$$CacheObject" =~ /spambox::/io && "$$CacheObject->{hashobj}" =~ /Tie::RDBM/oi;
          }; # make the fast select and clean the cache
          if ($@ or $failedTable{$KeyName}){  # try to reconnect if the select has failed - else do nothing
            $cdberror = 1;
            if ($@) {
                mlog(0,"warning: got database error $@ on table $mysqlTable - try to reconnect");
            } else {
                mlog(0,"warning: database table $mysqlTable has failed state - try to reconnect");
            }
            eval { undef $$CacheObject; untie %$KeyName;};
            eval {
                if ($DBusedDriver eq 'BerkeleyDB' && $CanUseBerkeleyDB) {
                    my $BerkeleyFile = $realFileName;
                    $BerkeleyFile =~ s/DB:/$FailoverValue/o;
                    $BerkeleyFile = "$base/$BerkeleyFile.bdb";
                    our %env = initBDBEnv($KeyName,$BerkeleyFile);
                    if ($dbGroup ne 'AdminGroup') {
                        $$CacheObject=tie %$KeyName, 'BerkeleyDB::Hash' , -Filename => $BerkeleyFile, %env;
                        BDB_filter($$CacheObject);
                    } else {
                        my $cmd = "'BerkeleyDB::Hash',-Filename => \"$BerkeleyFile\", \%main::env";
                        my $bin = $adminusersdbNoBIN ? 0 : 1 ;
                        $$CacheObject=tie %$KeyName,'SPAMBOX::CryptTie',$adminusersdbpass,$bin,$cmd;
                    }
                } else {
                    $dbh ||= DBI->connect("DBI:$DBusedDriver:".($mydb ? "database=$mydb;" : '').($myhost ? "$DBhostTag=$myhost" : '' )."$DBOption", $myuser, $mypassword,
                                            { PrintError=>0,
                            			      ChopBlanks=>1,
                            			      Warn=>0 }
                            			  );
                    if ($dbGroup ne 'AdminGroup') {
                        $$CacheObject=tie %$KeyName,'Tie::RDBM',{db=>$dbh,table=>"$mysqlTable",create=>1,DEBUG=>$DataBaseDebug};
                        $$CacheObject->{tableID} = $KeyName;
                    } else {
                        my $cmd = "'Tie::RDBM',\{db=>\$dbh,table=>\"$mysqlTable\",create=>1,DEBUG=>$DataBaseDebug\}";
                        my $bin = $adminusersdbNoBIN ? 0 : 1 ;
                        $$CacheObject=tie %$KeyName,'SPAMBOX::CryptTie',$adminusersdbpass,$bin,$cmd,$dbh;
                    }
                }
            };
            if($@) {
                mlog(0,"$mysqlFileName database error: $@");
                $realFileName =~ s/DB:/$FailoverValue/o;
                if ($dbGroup ne 'AdminGroup') {
                    mlog(0,"error: unable to use defined database - switching over to use $base/$realFileName instead of table $mysqlTable!");
                    mlog(0,"warning: from this time, the hash $KeyName will be different in every worker");
                    $$CacheObject=tie %$KeyName,'orderedtie',"$base/$realFileName";
                } else {
                    eval { undef $$CacheObject; untie %$KeyName;};
                    mlog(0,"warning: hash $KeyName is unavailable - only root is permitted to logon to GUI");
                }
                $failedTable{$KeyName} = 2;
            } else {
                mlog(0,"info: reusing table \<$mysqlTable\>  \tin $DBusedDriver Database \<$mydb\>");
                $failedTable{$KeyName} = 0;
            }
          }
        }
        if ($KeyName eq 'Spamdb' && ! $WorkerNumber && $haveSpamdb) {
            $currentDBVersion{Spamdb} = $Spamdb{'***DB-VERSION***'} || 'n/a';
            threads->yield;
        } elsif ($KeyName eq 'HMMdb' && ! $WorkerNumber && $haveHMM) {
            $currentDBVersion{HMMdb} = $HMMdb{'***DB-VERSION***'} || 'n/a';
            threads->yield;
        }
        eval{$$CacheObject->rdbm_cleanCache() if "$$CacheObject" =~ /Tie::RDBM/o;} if ! $WorkerNumber;
      }
  }
  d('chkdb - finished');
  $checkdb = undef;
  &sigonTry(__LINE__);
  return $cdberror;
}
