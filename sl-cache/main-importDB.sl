#line 1 "sub main::importDB"
package main; sub importDB {
   my ($name,$file,$mysqlTable,$cache,$cacherec,$recfac) = @_;
   my $importrpl="$base/$importDBDir/$file.rpl";
   my $importadd="$base/$importDBDir/$file.add";
   my $count;
   my $records;
   my $tempCache = $cache ? $cache : {};
   my $sql;
   my $sep;
   my $sqlmaxlen;
   my $dbh;
   my $dbn;
   my $dbv;
   my $dec;
   my $sth;
   my $k;
   my $v;
   my $f = 0;  # used by the statements in assp_db_import.cfg
   my ($dn,$ve,$dp,$ap,$is,$id,$se,$mr,$es);
   my $sql_sm;
   my @dbcfg;
   my $dkey;
   my $dodec;
   $recfac ||= 1;
   $dodec = 1 if $name eq 'AdminUsersRight';
   $dodec = 1 if $name eq 'AdminUsers';

   if ($cache && !($DBusedDriver eq 'BerkeleyDB' or $dodec or $preventBulkImport)) {
       $importrpl = 'cache';
   }

   return if (!(-e $importrpl || -e $importadd) && $importrpl ne 'cache');
   mlog_i(0,"database import started for table $mysqlTable");
   if ($DBusedDriver ne 'BerkeleyDB' && !-e "$base/assp_db_import.cfg"){
     mlog_i(0,"ERROR: unable to find file $base/assp_db_import.cfg - cancel import");
     return;
   }

   exportDB($name,$file,"backup",0) if $importrpl ne 'cache';   #overall - backup before update is the right way
   return if($WorkerNumber != 0 && ! $ComWorker{$WorkerNumber}->{run});

   if (-e $importrpl || $importrpl ne 'cache') {
       mlog_i(0,"replacing records in table $mysqlTable with records in file $importrpl") if $importrpl ne 'cache';
       ${$name}{'x1'} = '1'; #some databases need at least one record to delete all
       %$name=(); # clear the HASH
   }

   if (-e $importadd) {
      mlog_i(0,"adding records in file $importadd to table $mysqlTable");
   }

   $dec = SPAMBOX::CRYPT->new($adminusersdbpass,0) if $dodec;

   my @import = ($importrpl,$importadd);
   foreach my $importrpl (@import){
    $count = 0;
    $records = 0;
    if (-e $importrpl or $importrpl eq 'cache') {
       my $imp_start_time = time;
       my $last_step_time = $imp_start_time;
       my $toadd = 1000;
       my $IMP;
       if ($importrpl ne 'cache') {
           my $obj;
           if ($obj = tied %$name) {
               $obj = $obj->{hashobj} if $dodec;
               if ($obj =~ /BerkeleyDB/o) {
                  BDB_filter_off($obj);
               } else {
                  undef $obj;
               }
           }
           open($IMP, '<',"$importrpl");
           binmode($IMP);
           if ($DBusedDriver eq 'BerkeleyDB' or $dodec or $preventBulkImport or $RunTaskNow{ImportMysqlDB}) {
               while (<$IMP>) {
                   $records++;
               }
               close $IMP;
               open($IMP, '<',"$importrpl");
               binmode($IMP);
           }
           my $old_sec_left;
           my $sec_left;
           while (<$IMP>) {
                my ($k,$v) = $_ =~ /(.*)\002(.*)/;
                $count++;
                $v =~ s/\\r|\\n//go;
                $v =~ s/\r|\n//go;
                $k =~ s/\\r|\\n//go;
                $k =~ s/\r|\n//go;
                $k = $dec->DECRYPT($k) if $dodec && $k && $v;
                $v = $dec->DECRYPT($v) if $dodec && $k && $v;
                if (($k && $v) or ($k && defined $v && $dodec)) {
                     if ($DBusedDriver eq 'BerkeleyDB' or
                         $dodec or
                         $preventBulkImport or
                         $RunTaskNow{ImportMysqlDB}
                        )
                     {
                         ${$name}{$k} = $v;
                         if ($count % $toadd == 0 &&
                             ($sec_left = int(( time - $imp_start_time )*($records - $count)/$count)) != $old_sec_left)
                         {
                             $old_sec_left = $sec_left;
                             mlog_i(0,"added $count of $records records (force-RBR) for table $mysqlTable - finished in $sec_left sec");
                             &checkDBCon() if $WorkerNumber > 0;
                             &ThreadMonitorMainLoop("import $mysqlTable") if $WorkerNumber == 0;
                             my $stime = time - $last_step_time || 1;
                             $toadd = int(2 / $stime * $toadd);
                             $last_step_time = time;
                             return if($WorkerNumber != 0 && ! $ComWorker{$WorkerNumber}->{run});
                         }
                     } else {
                         $records++ if (! exists $tempCache->{$k});
                         $tempCache->{$k}=$v;
                     }
                }
           }
           close $IMP;

           if ($DBusedDriver eq 'BerkeleyDB' or $dodec or $preventBulkImport or $RunTaskNow{ImportMysqlDB}) {
               my $BDB; $BDB = " $DBusedDriver" if ($DBusedDriver eq 'BerkeleyDB' or $preventBulkImport);
               mlog_i(0,"successfully added $count records in to $BDB $name");
               rename("$importrpl","$importrpl.OK") or mlog(0,"Error: unable to rename $importrpl to $importrpl.OK");
               next;
           }

           mlog_i(0,"$records valid records of $count records found in $importrpl");
           BDB_filter($obj) if $obj;
       }
       
       if ($cache) {
           $records = $cacherec;
           ${$name}{'x1'} = '1'; #some databases need at least one record to delete all
           %$name=(); # clear the HASH
           if ($@ or ${$name}{'x1'} == 1) {
               sleep 5;
               $ThreadIdleTime{$WorkerNumber} += 5;
               %$name=(); # clear the HASH
           }
       }
       mlog_i(0,"trying Bulkimport for table $mysqlTable");

# first we are trying to make a fast Bulkimport - this should work for most of the databases

       $dbh = DBI->connect("DBI:$DBusedDriver:".($mydb ? "database=$mydb;" : '').($myhost ? "$DBhostTag=$myhost" : '' )."$DBOption", "$myuser", "$mypassword");
       if (!$dbh) {
           mlog_i(0,"Error: $DBI::errstr");
           mlog_i(0,"Import for table $mysqlTable canceled!");
           return;
       }

       $dbn = $dbh->get_info(17);
       $dbv = $dbh->get_info(18);
       mlog_i(0,"database: $dbn $dbv");
       if (!($dbn && $dbv)) {
           mlog_i(0,"ERROR: unable to get database information from DBI");
           mlog_i(0,"Import for table $mysqlTable canceled!");
           $dbh->disconnect() if ( $dbh );
           return;
       }

# find the right SQL statements in config file "assp_db_import.cfg"
       open($IMP, '<',"$base/assp_db_import.cfg");
       @dbcfg=<$IMP>;
       close $IMP;
       my %stm = ();
       my $di_version;
       my $di_modversion;
       foreach (@dbcfg) {     # process all lines
           chomp;
# version='2.2.2';
           $di_version = $1 if /^#\s*version[\D]*((?:\d+\.)+\d)/o;
# modversion='(1.0.1)';
           $di_modversion = $1 if /^#\s*modversion[\D]*(\d[\d\.]+)/o;
           next if /^#/o;
           ($dn,$ve,$dp,$ap,$is,$id,$se,$mr,$es) = split/\|/o;
           next if (!$dn);
           $stm{lc($dn).$ve."dp"}=$dp;
           $stm{lc($dn).$ve."ap"}=$ap;
           $stm{lc($dn).$ve."is"}=$is;
           $stm{lc($dn).$ve."id"}=$id;
           $stm{lc($dn).$ve."se"}=$se;
           $stm{lc($dn).$ve."mr"}=$mr;
           $stm{lc($dn).$ve."es"}=$es;
       }
       if ($di_version && $di_modversion) {
           mlog_i(0,"Info: version $di_version($di_modversion) of file $base/assp_db_import.cfg is used for the import");
       } else {
           mlog_i(0,"Warning: no valid version information found in file $base/assp_db_import.cfg");
       }

# find the statements
# first this with both - database and version are wildcards (SQL-ANSI-92)
# second this with the right database and version is wildcards
# third this with the right database and the right version


       if ( exists $stm{'**dp'}) {$dp=$stm{'**dp'}; $ap=$stm{'**ap'}; $is=$stm{'**is'}; $id=$stm{'**id'}; $se=$stm{'**se'};$mr=$stm{'**mr'};$es=$stm{'**es'};}
       if ( exists $stm{lc($dbn).'*dp'}) {$dp=$stm{lc($dbn).'*dp'}; $ap=$stm{lc($dbn).'*ap'}; $is=$stm{lc($dbn).'*is'}; $id=$stm{lc($dbn).'*id'}; $se=$stm{lc($dbn).'*se'}; $mr=$stm{lc($dbn).'*mr'}; $es=$stm{lc($dbn).'*es'};}
       if ( exists $stm{lc($dbn).$dbv.'dp'}) {$dp=$stm{lc($dbn).$dbv.'dp'}; $ap=$stm{lc($dbn).$dbv.'ap'}; $is=$stm{lc($dbn).$dbv.'is'}; $id=$stm{lc($dbn).$dbv.'id'}; $se=$stm{lc($dbn).$dbv.'se'}; $mr=$stm{lc($dbn).$dbv.'mr'}; $es=$stm{lc($dbn).$dbv.'es'};}

# get the types of fields - they may differ depending on the used DB engine
# at this time, this is only needed for MS-SQL to build the right CONVERT statement
# this is to be expanded if any DB require CAT- or SCHEMA-definition (see primary key)
       my $db_info;
       my ($pkey_TYPE_NAME,$pkey_SIZE);
       my ($pvalue_TYPE_NAME,$pvalue_SIZE);
       my ($pfrozen_TYPE_NAME,$pfrozen_SIZE);
       
       ($sth = $dbh->column_info( undef, undef, $mysqlTable, 'pkey' )) and
       ($db_info = $sth->fetchrow_arrayref) and
       ($pkey_TYPE_NAME = $db_info->[5]) and
       ($pkey_SIZE = $db_info->[6]);
       if ($pkey_SIZE != 254) {
           mlog_i(0,"Warning: the column size of pkey in table $mydb/$mysqlTable is $pkey_TYPE_NAME($pkey_SIZE), but it should be $pkey_TYPE_NAME(254)");
           $pkey_SIZE = 254;
       }

       ($sth = $dbh->column_info( undef, undef, $mysqlTable, 'pvalue' )) and
       ($db_info = $sth->fetchrow_arrayref) and
       ($pvalue_TYPE_NAME = $db_info->[5]) and
       ($pvalue_SIZE = $db_info->[6]);
       if ($pvalue_SIZE != 255) {
           mlog_i(0,"Warning: the column size of pvalue in table $mydb/$mysqlTable is $pvalue_TYPE_NAME($pvalue_SIZE), but it should be $pvalue_TYPE_NAME(255)");
           $pvalue_SIZE = 255;
       }

       ($sth = $dbh->column_info( undef, undef, $mysqlTable, 'pfrozen' )) and
       ($db_info = $sth->fetchrow_arrayref) and
       ($pfrozen_TYPE_NAME = $db_info->[5]) and
       ($pfrozen_SIZE = $db_info->[6]);

# get the name of the primary key
       $sth = $dbh->primary_key_info( undef, undef , $mysqlTable ); # for MSSQL, MySQL
       eval{$db_info = $sth->fetchrow_arrayref ;};
       my($TABLE_CAT,$TABLE_SCHEM,$TABLE_NAME,$COLUMN_NAME,$KEY_SEQ,$PK_NAME) = @$db_info ;
       if (!$TABLE_NAME) {
          $sth = $dbh->primary_key_info( undef, undef , uc($mysqlTable));
          eval{$db_info = $sth->fetchrow_arrayref ;};
          ($TABLE_CAT,$TABLE_SCHEM,$TABLE_NAME,$COLUMN_NAME,$KEY_SEQ,$PK_NAME) = @$db_info ;
       }
       if (!$TABLE_NAME) {
          $sth = $dbh->primary_key_info( undef, undef , lc($mysqlTable));     # for Pg
          eval{$db_info = $sth->fetchrow_arrayref ;};
          ($TABLE_CAT,$TABLE_SCHEM,$TABLE_NAME,$COLUMN_NAME,$KEY_SEQ,$PK_NAME) = @$db_info ;
       }
       if (!$TABLE_NAME) {
          $sth = $dbh->primary_key_info( undef, $myuser , $mysqlTable );
          eval{$db_info = $sth->fetchrow_arrayref ;};
          ($TABLE_CAT,$TABLE_SCHEM,$TABLE_NAME,$COLUMN_NAME,$KEY_SEQ,$PK_NAME) = @$db_info ;
       }
       if (!$TABLE_NAME) {
          $sth = $dbh->primary_key_info( undef , uc($myuser) , uc($mysqlTable));  # for Oracle
          eval{$db_info = $sth->fetchrow_arrayref ;};
          ($TABLE_CAT,$TABLE_SCHEM,$TABLE_NAME,$COLUMN_NAME,$KEY_SEQ,$PK_NAME) = @$db_info ;
       }

       if (!$TABLE_NAME) {
          mlog_i(0,"ERROR: unable to get primary-key info for table $mysqlTable - cancel import");
          return;
       }

       my $DBG;
       if ($DataBaseDebug or $debug) {open($DBG,'>',"$base/debug/sql_import_$mysqlTable.".time.'.txt'); binmode($DBG);}
       mlog_i(0,"removing PRIMARY KEY $PK_NAME from table $mysqlTable") if ( $PK_NAME && $dp !~ /NOOP/o);
# remove primary key - if we do not do this, the import may fail on duplicate keys!!!
       if ($dp !~ /NOOP/o) {
           eval ($dp);
           print $DBG "error in dp - $dp - $@\n" if $DBG && $@;
       }
       $sql=$sql_sm;
       if ( $PK_NAME && $dp !~ /NOOP/o) {
           $sth = $dbh->do($sql);
           $dbh->commit unless $main::DBautocommit;
       }
       $count = 0;
       eval ($se);
       print $DBG "error in se - $se - $@\n" if $DBG && $@;
# set the separator for the middle of the INSERT statement
       $sep=$sql_sm;
       eval ($is);
       print $DBG "error in is - $is - $@\n" if $DBG && $@;
       $sql=$sql_sm;
       my $max = 10;
       $sqlmaxlen = int($mr * $recfac) || $max;  # 2000 tested for mysql - absolute limit is ~5000 - so we are save (defined in assp_db_import.cfg)
       my $sqllen = int($sqlmaxlen/$max)*$max || $max;
       $imp_start_time = time;
       $last_step_time = $imp_start_time;
# build the INSERT statement from the statements in assp_db_import.cfg and the values in $k,$v
# do this until all record have been inserted or $DBI::err
       my $old_sec_left;
       my $sec_left;
       while (my ($k,$v)=each(%{$tempCache})) {
           $k = $dbh->quote($k);   # let's DBI do the quoting - depends on the driver
           $v = $dbh->quote($v);
           next if (! $k || $k eq 'NULL');
           $count++;
           $sep = '' if ($count == $records or int($count/$sqllen) == $count/$sqllen);
           eval ($id);
           print $DBG "error in id - $id - $@\n" if $DBG && $@;
           $sql .= $sql_sm.$sep;
           if ($count == $records or int($count/$sqllen) == $count/$sqllen) {
              if ($es) {
                  eval ($es);
                  print $DBG "error in es - $es - $@\n" if $DBG && $@;
                  $sql .= $sql_sm;
              }
              print $DBG "SQL: $sql\n" if $DBG;
              $sth = $dbh->do($sql);
              $dbh->commit unless $main::DBautocommit;
              last if ($DBI::err);
              if ($count % 1000 == 0 && ($sec_left = int(( time - $imp_start_time )*($records - $count)/$count)) != $old_sec_left) {
                  $old_sec_left = $sec_left;
                  mlog_i(0,"added $count of $records records (BULK) for table $mysqlTable - finished in $sec_left sec");
                  &checkDBCon() if $WorkerNumber > 0;
                  &ThreadMonitorMainLoop("import $mysqlTable") if $WorkerNumber == 0;
                  last if($WorkerNumber != 0 && ! $ComWorker{$WorkerNumber}->{run});
              }
# reset the separator and the begin of the insert statement
              eval ($se);
              print $DBG "error in se - $se - $@\n" if $DBG && $@;
              $sep = $sql_sm;
              eval ($is);
              print $DBG "error in is - $is - $@\n" if $DBG && $@;
              $sql = $sql_sm;
# calculate the number of record that can be added in 2 seconds
              my $stime = time - $last_step_time || 1;
              $sqllen = int(2 / $stime * $sqllen /$max)*$max;
              if ($sqllen <= $max) {$sqllen = $max;}
              elsif ($sqllen > $sqlmaxlen) {$sqllen = $sqlmaxlen;}
              $last_step_time = time;
           }
       }
       if ($DBI::err) {
# Bulk import has failed - so we are using STD-method - witch may take a long time
              mlog_i(0,"Error: $DBI::errstr");
              mlog_i(0,"Error: Bulkimport for table $mysqlTable canceled - doing normal import");
# clearing the HASH (delete * from ...) and add the primary key
              ${$name}{'x1'} = '1';
              %$name=();
              if ( $PK_NAME && $ap !~ /NOOP/o) {
                  mlog_i(0,"adding primary key $PK_NAME to table $mysqlTable");
                  eval ($ap);
                  print $DBG "error in ap - $ap - $@\n" if $DBG && $@;
                  $sql=$sql_sm;
                  $sth = $dbh->do($sql);
                  $dbh->commit unless $main::DBautocommit;
              }
              $dbh->disconnect() if ( $dbh );
# Bulk import failed - so doing the import record by record with the tied HASH
              $count = 0;
              my $imp_start_time = time;
              my $last_step_time = $imp_start_time;
              my $toadd = 500;
              while (my ($k,$v)=each(%{$tempCache})) {
                 next unless $k;
                 ${$name}{$k} = $v;
                 $count++;
                 if ($count % $toadd == 0 && ($sec_left = int(( time - $imp_start_time )*($records - $count)/$count)) != $old_sec_left) {
                    $old_sec_left = $sec_left;
                    mlog_i(0,"added $count of $records records (RBR) for table $mysqlTable - finished in $sec_left sec");
                    &checkDBCon() if $WorkerNumber > 0;
                    &ThreadMonitorMainLoop("import $mysqlTable") if $WorkerNumber == 0;
                    my $stime = time - $last_step_time || 1;
                    $toadd = int(2 / $stime * $toadd);
                    $last_step_time = time;
                    last if($WorkerNumber != 0 && ! $ComWorker{$WorkerNumber}->{run});
                 }
              }
       } else {
            mlog_i(0,"Bulkimport for table $mysqlTable finished");
# we have to remove duplicate keys from pkey before add the primary key to the table
            if ($ap !~ /NOOP/o ) {   # if $ap is NOOP the primary key was not removed above - so the table must be OK
              mlog_i(0,"removing duplicate keys from table $mysqlTable");
              my $dup_key;
              $dkey=0;
# run this loop until there are no duplicate keys in the table
              do {
                 $dup_key = 0;
                 $sql ="SELECT pkey FROM $mysqlTable GROUP BY pkey HAVING count(*) > 1";
                 $sth = $dbh->prepare($sql);
                 $sth->execute;
                 while ( my ($pkey) = $sth->fetchrow_array ) {   # all duplicate records are in this array
                     $pkey = $dbh->quote($pkey);   # let's DBI do the quoting - depends on the driver
                     $sql ="SELECT * FROM $mysqlTable WHERE pkey=$pkey";   # get all records for this duplicate key
                     my $sthh = $dbh->prepare($sql);
                     $sthh->execute;
                     my ($pkey_add,$pvalue_add,$pfrozen_add) = $sthh->fetchrow_array ;
                     $sql ="DELETE FROM $mysqlTable WHERE pkey=$pkey";   # get all records for this duplicate key
                     $sthh = $dbh->prepare($sql);
                     $sthh->execute;
                     $dbh->commit unless $main::DBautocommit;
                     ${$name}{$pkey_add}=$pvalue_add ; # add the first record
                     $dup_key = 1;
                     $dkey++;
                 }
              } while ($dup_key);
              mlog_i(0,"removed $dkey duplicate keys from table $mysqlTable") if ($dkey);
              $PK_NAME = "PK_$mysqlTable" if (! $PK_NAME); # a primary key is needed
              mlog_i(0,"adding primary key $PK_NAME to table $mysqlTable") if ( $PK_NAME && $ap !~ /NOOP/o);
              eval ($ap);
              print $DBG "error in ap - $ap - $@\n" if $DBG && $@;
              $sql = $sql_sm;
              if ( $PK_NAME ) {
                  $sth = $dbh->do($sql) ;
                  $dbh->commit unless $main::DBautocommit;
              }
            }
            $dbh->disconnect() if ( $dbh );
            delete ${$name}{''};
       }
       close($DBG) if $DBG;
       $count = $count - $dkey;
       mlog_i(0,"successfully added $count records in to table $mysqlTable");
       if (! $cache) {
           rename("$importrpl","$importrpl.OK") or mlog_i(0,"Error: unable to rename $importrpl to $importrpl.OK");
       }
    }
   }
}
