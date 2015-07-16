#line 1 "sub main::exportDB"
package main; sub exportDB {
  my ($name,$file,$action,$realFileName)=@_;
  my $export;
  my $i;
  my $enc;
  my $doenc = 0;
  $doenc = 1 if $name eq 'AdminUsersRight';
  $doenc = 1 if $name eq 'AdminUsers';
  $realFileName = "$base/$realFileName" if ($realFileName);
  $export="$base/$exportDBDir/$file" if (lc($action)=~/export/o);
  $export="$base/$backupDBDir/$file" if (lc($action)=~/backup/o);
  mlog_i(0,"$action: starting $action database table $name to file $export");
  unlink "$export.9";
  for ($i=8;$i>0;$i--) {
     my $j=$i+1;
     rename("$export.$i","$export.$j");
  }
  rename("$export","$export.1");
  my $count=0;

  $enc = SPAMBOX::CRYPT->new($adminusersdbpass,0) if $doenc;
  my $obj;
  if ($obj = tied %$name) {
      $obj = $obj->{hashobj} if $doenc;
      if ($obj =~ /BerkeleyDB/o) {
         BDB_filter_off($obj);
      } else {
         undef $obj;
      }
  }
  my $EXP;
  open($EXP, '>',"$export");
  binmode($EXP);
  print $EXP "\n";
  while (my ($k,$v)=each(%$name)) {
     if ($k) {
         if ($doenc && $enc) {
             $k = $enc->ENCRYPT($k);
             $v = $enc->ENCRYPT($v);
         }
         print $EXP "$k\002$v\n";
         $count++;
     }
     if ($count%1000 == 0) {
         threads->yield();
         ThreadMaintMain2() if $WorkerNumber == 10000;
         if ($WorkerNumber == 0 ) {
             &ThreadMonitorMainLoop("$action $name");
         } else {
             last if(! $ComWorker{$WorkerNumber}->{run});
         }
     }
  }
  close $EXP;
  BDB_filter($obj) if $obj;
  mlog_i(0,"$action: ".nN($count)." records of database table $name to file $export");

  if ($copyDBToOrgLoc && lc($action)=~/backup/o && $realFileName){
    if (copy("$export","$realFileName")) {
        mlog_i(0,"$action: ".nN($count)." records of database table $name to file $realFileName");
    } else {
        mlog_i(0,"$action: unable to copy file $export to file $realFileName - $!");
    }
  }
}
