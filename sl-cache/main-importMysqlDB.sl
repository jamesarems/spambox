#line 1 "sub main::importMysqlDB"
package main; sub importMysqlDB {
  my $action = "import";
  return unless $DBisUsed;
  if (!$CanUseTieRDBM && !$CanUseBerkeleyDB) {
    mlog(0,"error: can not $action - database support is not available");
    mlog(0,"Please check the configuration and restart assp!");
    mlog(0,"You have to restart assp, if you changed any database relevant configuration parameters!!!");
    return;
  }
  &checkDBCon();
  foreach my $dbGroup (@GroupList) {
      foreach my $dbGroupEntry (@$dbGroup) {
        my ($KeyName,$dbConfig,$CacheObject,$realFileName,$mysqlFileName,$FailoverValue,$mysqlTable) = split(/,/o,$dbGroupEntry);
        importDB($KeyName,$mysqlFileName,$mysqlTable,'','','') if (${$dbConfig} =~ /DB:/o && ! $failedTable{$KeyName});
        &checkDBCon();
      }
  }
}
