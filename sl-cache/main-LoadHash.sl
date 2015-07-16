#line 1 "sub main::LoadHash"
package main; sub LoadHash {
   my ($hash,$file,$ignorefile) = @_;
   my $LH;
   my @s = $stat->($file);
   my $size = $s[7];
   my $keys = $file =~ /black|spamdb|hmmdb/io ? int($size * 2 / 80) + 128 : int($size * 2 / 26) + 128;
   my $count = 0;
   my $hashname = $hash;
   $hashname =~ s/^main:://o;
   lock(%$hash) if is_shared(%$hash);
   unless (open($LH, '<',"$file")) {
       mlog(0,"warning: unable to open $file to load $hashname");
       return;
   }
   binmode($LH);
   %$hash = ();
   keys (%$hash) = $keys;      # preallocate Memory for Hash
   mlog(0,"info: start loading $hashname from $file with approx. $keys") if $MaintenanceLog;
   while (<$LH>) {
     my ($k,$v) = split/\002/o;
     chomp $v;
     $v =~ s/(?:\r|\n)$//go;
     if ($k && $v) {
       ${$hash}{$k}=$v;
       $count++;
     }
     if (!($count % 10000)) {
         if ($WorkerNumber == 0) {
             if ($WorkerName !~ /start|init/io) {
                 &ThreadMonitorMainLoop("loading $hashname - $count records loaded from approx. $keys");
                 MainLoop2();
             }
         }  elsif ($WorkerNumber > 0 && $WorkerNumber < 10000) {
             $WorkerLastAct{$WorkerNumber} = time;
             &NewSMTPConCall();
         }
     }
   }
   close $LH;
   mlog(0,"info: $hashname loaded from $file with $count records") if $MaintenanceLog;
   if ($count > 1000) {
       foreach my $dbGroup (@GroupList) {
           next if ($HMM4ISP && $dbGroup eq 'spamdbGroup');
           foreach my $dbGroupEntry (@$dbGroup) {
               my ($KeyName,$dbConfig,$CacheObject,$realFileName,$mysqlFileName,$FailoverValue,$mysqlTable) = split(/,/o,$dbGroupEntry);
               next if $KeyName ne $hash;
               if ($count < 2000) {
                   mlog(0,"warning: $hashname contains $count records - it is recommended to use a database for '$dbConfig' to prevent memory leaking") if (! $EnableHighPerformance || $EnableHighPerformance > 500);
               } else {
                   my $i = $count * 2;
                   my $exp = 7;
                   while ($i >= 2) {
                       $i = int($i / 2);
                       $exp++;
                   }
                   $i = 2 ** $exp + $count * 4 + ($size * ($NumComWorkers + 3));
                   mlog(0,"error: $hashname contains $count records (allocating approx. " . &formatDataSize($i,1) . " shared memory) - it is highly recommended to use a database for '$dbConfig' to reduce memory usage and to prevent memory leaking") if (! $EnableHighPerformance || $EnableHighPerformance > 500);
               }
           }
       }
   }
   return if ($ignorefile);

   my $mtime=$s[9];
   $hash = 'main::'.$hash if $hash !~ /::/o;
   if (is_shared(%$hash)) {
       $FileHashUpdateTime{"$file"} = $mtime;
       $FileHashUpdateHash{"$file"} = $hash;
   } else {
       $FileHashUpdateTimeUS{"$file"} = $mtime;
       $FileHashUpdateHashUS{"$file"} = $hash;
   }
}
