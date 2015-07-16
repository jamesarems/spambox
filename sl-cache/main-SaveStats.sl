#line 1 "sub main::SaveStats"
package main; sub SaveStats {
 d('SaveStats');
 for ('rcptReportHelp', 'rcptReportAnalyze') {
     delete $Stats{$_};
     delete $OldStats{$_};
     delete $AllStats{$_};
 }
 lock(%Stats) if (is_shared(%Stats));
 mlog(0,"info: saving Stats in file spamboxstats.sav") if $MaintenanceLog;
 $Stats{smtpConcurrentSessions}=$smtpConcurrentSessions;
 ScheduleMapSet('SaveStatsEvery') if $WorkerName ne 'Shutdown';;
 &StatAllStats();
 my $SS;
 if (open($SS,'>',"$base/spamboxstats.sav")) {
     print $SS join("\001",%AllStats);
     close $SS;
 } else {
     mlog(0,"warning: unable to save STATS to $base/spamboxstats.sav - $!");
 }

 my $time = timestring('','','YYYY-MM-DD_hh:mm:ss');
 my $fext = substr($time,0,7);
 if ($enableGraphStats && open($SS, '>>', "$base/logs/statGraphStats-$fext.txt")) {
     binmode $SS;
     foreach (sort {lc($main::a) cmp lc($main::b)} keys(%AllStats)) {
         next if /^(?:nextUpload|version|starttime)$/o;
         $AllStats{$_} ||= 0;
         print $SS "$time $_: $AllStats{$_}\n";
     }
     close $SS;
 }

 mlog(0,"info: saving ScoreStats in file spamboxscorestats.sav") if $MaintenanceLog;
 if (open($SS,'>',"$base/spamboxscorestats.sav")) {
     print $SS join("\001",%AllScoreStats);
     close $SS;
 } else {
     mlog(0,"warning: unable to save scoring STATS to $base/spamboxscorestats.sav - $!");
 }

 if ($enableGraphStats && open($SS, '>>', "$base/logs/scoreGraphStats-$fext.txt")) {
     binmode $SS;
     foreach (sort {lc($main::a) cmp lc($main::b)} keys(%AllScoreStats)) {
         $AllScoreStats{$_} ||= 0;
         print $SS "$time $_: $AllScoreStats{$_}\n";
     }
     close $SS;
 }

 if ($enableGraphStats && $baysConf && open($SS, '>>', "$base/logs/confidenceGraphStats-$fext.txt")) {
     binmode $SS;
     for my $hash (qw(bayesconf_ham bayesconf_spam hmmconf_ham hmmconf_spam)) {
         foreach my $conf(sort keys(%{$hash})) {
             my $count = ${$hash}{$conf};
             print $SS "$time $hash: $conf: $count\n";
         }
         %{$hash} = ();
         threads->yield();
     }
     close $SS;
 } else {
     %{$_} = () for (qw(bayesconf_ham bayesconf_spam hmmconf_ham hmmconf_spam));
 }
}
