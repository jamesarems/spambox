#line 1 "sub main::StatAllStats"
package main; sub StatAllStats {
 %AllStats=%OldStats;
 &StatCpuStats();
 $AllStats{starttime}=$OldStats{starttime} || $Stats{starttime};
 foreach (keys %Stats) {
  if ($_ eq 'version' or $_ eq 'Counter') {
   # just copy
   $AllStats{$_}=$Stats{$_};
  } elsif ($_ eq 'smtpMaxConcurrentSessions') {
   # pick greater value
   $AllStats{$_}=$Stats{$_} if $Stats{$_}>$AllStats{$_};
  } else {
   $AllStats{$_}+=$Stats{$_};
  }
 }
 $AllStats{starttime}=$OldStats{starttime} || $Stats{starttime};

 %AllScoreStats=%OldScoreStats;
 foreach (keys %ScoreStats) {
   $AllScoreStats{$_}+=$ScoreStats{$_};
 }
}
