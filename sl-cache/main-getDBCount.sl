#line 1 "sub main::getDBCount"
package main; sub getDBCount {
  my ($hash,$config) = @_;
  my $hashObject = $hash.'Object';
  my $i = 0;
  if ($hash =~ /HMMdb/o && $runHMMusesBDB) {
      $i = BDB_getRecordCount($hash);
  } elsif ($DBusedDriver eq 'BerkeleyDB' && $CanUseBerkeleyDB && ${$config} =~ /DB:/o) {
      $i = BDB_getRecordCount($hash);
  } elsif (${$config} =~ /DB:/o) {
      $i = rdbm_COUNT(${$hashObject});
      if (! $i) {
          $i = scalar keys %{$hash};
          if ($i) {
              my $table;
              eval {$table = ${$hashObject}->{table};};
              $table ||= 'N/A';
              mlog(0,"error: SQL -> 'SELECT COUNT(*) FROM $table' returned a zero count of records for '$hash', but there are at least $i records in table '$table' - check your database engine!");
          }
      }
  } else {
      $i = scalar keys %{$hash};
  }
  return $i;
}
