#line 1 "sub main::ResetStats"
package main; sub ResetStats {
 d('ResetStats');
 lock(%Stats) if (is_shared(%Stats));
 foreach (keys %Stats) {
     next if $_ eq 'version';
     next if $_ eq 'Counter';
     $Stats{$_} = 0;
 }
 $Stats{nextUpload} = $nextStatsUpload = time+3600*8;
 $Stats{starttime} = time;
 for (0,1...$NumComWorkers,10000,10001) {
    $ThreadIdleTime{$_} = 0;
 }

 my $RSf;
 my $tosave = 0;
 if (open( $RSf,'<',"$base/asspstats.sav")) {
     (%OldStats)=split(/\001/o,<$RSf>);
     close $RSf;
 } elsif (-e "$base/asspstats.sav") {
     mlog(0,"error: unable to open file $base/asspstats.sav for reading - $!");
 } else {
     $tosave = 1;
 }
 if (open($RSf,'<',"$base/asspscorestats.sav")) {
     (%OldScoreStats)=split(/\001/o,<$RSf>);
     close $RSf;
 } elsif (-e "$base/asspscorestats.sav") {
     mlog(0,"error: unable to open file $base/asspscorestats.sav for reading - $!");
 } else {
     $tosave = 1;
 }
 foreach (keys %ScoreStats, keys %OldScoreStats) {
     $ScoreStats{$_} = 0;
 }

 $Stats{Counter} = $OldStats{Counter};
 # conversion from previous versions
 if (exists $OldStats{messages}) {
  $OldStats{smtpConn}=$OldStats{connects};
  $OldStats{smtpConnLimit}=$OldStats{maxSMTP};
  $OldStats{smtpConnLimitIP}=$OldStats{maxSMTPip};
  $OldStats{viri}-=$OldStats{viridetected}; # fix double counting
  $OldStats{rcptRelayRejected}=$OldStats{norelays};
  # remove unused entries
  delete $OldStats{connects};
  delete $OldStats{maxSMTP};
  delete $OldStats{maxSMTPip};
  delete $OldStats{messages};
  delete $OldStats{spams};
  delete $OldStats{hams};
  delete $OldStats{norelays};
  delete $OldStats{testmode};
  $tosave = 1;
 }
 if ($OldStats{cpuTime} < 0 || $OldStats{cpuTime} < $OldStats{cpuBusyTime}) {
  $OldStats{cpuTime} = $OldStats{cpuBusyTime} = 0;
  $tosave = 1;
 }
 SaveStats() if $tosave;
}
