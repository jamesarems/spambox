#line 1 "sub main::ResetAllStats"
package main; sub ResetAllStats {
     %OldStats = ();
     %AllStats = ();
     %OldScoreStats = ();
     %AllScoreStats = ();
     $AllStats{starttime} = time;
     unlink("$base/spamboxstats.sav.bak");
     unlink("$base/spamboxscorestats.sav.bak");
     rename("$base/spamboxstats.sav","$base/spamboxstats-".timestring('','','YYYY-MM-DD-hh-mm-ss').'.sav');
     rename("$base/spamboxscorestats.sav","$base/spamboxscorestats-".timestring('','','YYYY-MM-DD-hh-mm-ss').'.sav');
     ResetStats();
}
