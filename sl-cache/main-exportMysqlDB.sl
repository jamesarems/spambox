#line 1 "sub main::exportMysqlDB"
package main; sub exportMysqlDB {
  my $action = shift;
  return unless $DBisUsed;
  if (! $CanUseTieRDBM && ! $CanUseBerkeleyDB) {
    mlog(0,"error: can not $action - database support is not available");
    mlog(0,"Please check the configuration and restart spambox!");
    mlog(0,"You have to restart spambox, if you changed any database related configuration parameters!!!");
    return;
  }
  &checkDBCon();
  foreach my $dbGroup (@GroupList) {
      foreach my $dbGroupEntry (@$dbGroup) {
        my ($KeyName,$dbConfig,$CacheObject,$realFileName,$mysqlFileName,$FailoverValue,$mysqlTable) = split(/,/o,$dbGroupEntry);
        $realFileName =~ s/DB:/$FailoverValue/o;
        exportDB($KeyName,$mysqlFileName,$action,$realFileName) if (${$dbConfig} =~ /DB:/o && ! $failedTable{$KeyName});
        &checkDBCon();
      }
  }
}
