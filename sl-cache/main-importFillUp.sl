#line 1 "sub main::importFillUp"
package main; sub importFillUp {
  my $filever = shift;
  $filever = uc($filever);
  d("importFillUp - $filever");
  return unless $filever =~ /^[L0-9]$/io;
  return unless $DBisUsed;
  return unless $backupDBDir && $importDBDir;
  $filever = '.' . $filever;
  $filever = '' if $filever eq '.L';
  foreach my $dbGroup (@GroupList) {
      foreach my $dbGroupEntry (@$dbGroup) {
        my ($KeyName,$dbConfig,$CacheObject,$realFileName,$mysqlFileName,$FailoverValue,$mysqlTable) = split(/,/o,$dbGroupEntry);
        next if ${$dbConfig} !~ /DB:/o;
        my $src="$base/$backupDBDir/$mysqlFileName$filever";
        my $tar="$base/$importDBDir/$mysqlFileName.rpl";
        if (copy($src,$tar)) {
            mlog(0,"info: copied file $src to $tar");
        } else {
            mlog(0,"warning: unable to copy file $src to $tar - $!");
        }
      }
  }
}
