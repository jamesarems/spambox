#line 1 "sub main::CheckTableStructure"
package main; sub CheckTableStructure {
  my $mysqlTable = shift;
  my $sql;
  my $dbh;
  my $sth;

  $dbh = DBI->connect("DBI:$DBusedDriver:".($mydb ? "database=$mydb;" : '').($myhost ? "$DBhostTag=$myhost" : '' )."$DBOption", "$myuser", "$mypassword");
  if (!$dbh) {
    mlog(0,"Error: $DBI::errstr");
    mlog(0,"MySQL check for table $mysqlTable canceled!");
    $dbh->disconnect() if ( $dbh );
    return;
  }

  my $db_features = $Tie::RDBM::Types{$DBusedDriver};
  my($keytype,$valuetype,$frozentype) = @{$db_features};

  $sth = $dbh->column_info( undef, undef, $mysqlTable, 'pkey' );
  my $db_info;
  eval{$db_info = $sth->fetchrow_arrayref} ;
  if($@) {
    mlog(0,"warning: your mysql driver does not support GET-COLUMNE-INFO");
    mlog(0,"driver version is $DBD::mysql::VERSION - should be at least 4.005");
    $dbh->disconnect() if ( $dbh );
    return;
  }
  my $pkey_TYPE_NAME = @$db_info[37];

  if (lc($pkey_TYPE_NAME) ne lc($keytype)) {
    mlog(0,"info: convert field pkey in table $mysqlTable from $pkey_TYPE_NAME to $keytype");
    $sql="ALTER TABLE $mysqlTable MODIFY COLUMN pkey $keytype NOT NULL";
    $sth = $dbh->do($sql);
    $dbh->commit unless $main::DBautocommit;
    if (!$dbh) {
      mlog(0,"Error: $DBI::errstr");
      mlog(0,"conversion for table $mysqlTable failed!");
    }
  }

  $sth = $dbh->column_info( undef, undef, $mysqlTable, 'pvalue' );
  $db_info = $sth->fetchrow_arrayref ;
  my $pvalue_TYPE_NAME = @$db_info[37];

  if (lc($pvalue_TYPE_NAME) ne lc($valuetype)) {
    mlog(0,"info: convert field pvalue in table $mysqlTable from $pvalue_TYPE_NAME to $valuetype");
    $sql="ALTER TABLE $mysqlTable MODIFY COLUMN pvalue $valuetype DEFAULT NULL";
    $sth = $dbh->do($sql);
    $dbh->commit unless $main::DBautocommit;
    if (!$dbh) {
      mlog(0,"Error: $DBI::errstr");
      mlog(0,"conversion for table $mysqlTable failed!");
    }
  }
# conversion for pfrozen is not needed - it was never changed
  $dbh->disconnect() if ( $dbh );
}
