#line 1 "sub main::SaveHash"
package main; sub SaveHash {
  my $HashName = shift;
  $HashName =~ s/^main:://o;
  d("SaveHash - $HashName");
  &ThreadMaintMain2() if $WorkerNumber == 10000;
  my $filename;
  foreach my $dbGroup (@GroupList) {
      foreach my $dbGroupEntry (@$dbGroup) {
        my ($KeyName,$dbConfig,$CacheObject,$realFileName,$mysqlFileName,$FailoverValue,$mysqlTable) = split(/,/o,$dbGroupEntry);
        if ($KeyName eq $HashName){
            if (!(($CanUseTieRDBM or $CanUseBerkeleyDB) && ${$dbConfig} =~ /DB:/o)) {
               return  if (! ${$dbConfig});
               my $tempFile = "$base/$realFileName.tmp";
               my $bakfile = "$base/$realFileName.bak";
               $realFileName = "$base/$realFileName";
               $filename = $realFileName;
               $tempFile =~ s/\\/\//go;
               $bakfile =~ s/\\/\//go;
               $realFileName =~ s/\\/\//go;
               my $HASH;
               unless (open($HASH, '>',"$tempFile")) {
                   mlog(0,"error: unable to open $tempFile for writing - $!");
                   return;
               }
               binmode $HASH;
               print $HASH "\n";
               my $count = 0;
               mlog(0,"Info: start saving $KeyName") if $MaintenanceLog;
               my @h;
               {
                   lock(%$HashName) if is_shared(%$HashName) && $WorkerName ne 'Shutdown';
                   @h = sort keys %$HashName;
               }
               while (@h) {
                  (my $k = shift @h) or next;
                  my $v = ${$HashName}{$k};
                  print $HASH "$k\002$v\n";
                  $count++;
               }
               close $HASH;
               $! = undef;
               if (-e "$bakfile") {
                   unlink($bakfile);
                   if ($!) {
                       mlog(0,"error: unable to delete file $bakfile - $!");
                       return;
                   }
               }
               $! =undef;
               rename("$realFileName", "$bakfile") if (-e "$realFileName");
               if ($! && -e "$realFileName") {
                   mlog(0,"error: unable to rename file $realFileName to $bakfile - $!");
                   return;
               }
               $! = undef;
               rename("$tempFile", "$realFileName");
               if ($! && -e "$tempFile") {
                   mlog(0,"error: unable to rename file $tempFile to $realFileName - $!");
                   rename("$bakfile", "$realFileName");
                   mlog(0,"error: unable to rename file $bakfile to $realFileName - $!") if $!;
                   return;
               }
               mlog(0,"Info: $count records of $KeyName saved") if $MaintenanceLog;
               $HashName = 'main::'.$HashName if $HashName !~ /::/o;
               if (is_shared(%$HashName)) {
                   $FileHashUpdateTime{"$filename"} = ftime($realFileName);
                   $FileHashUpdateHash{"$filename"} = $HashName;
               } else {
                   $FileHashUpdateTimeUS{"$filename"} = ftime($realFileName);
                   $FileHashUpdateHashUS{"$filename"} = $HashName;
               }
            }
        }
      }
  }
  mlogWrite() if $WorkerNumber == 0;
}
