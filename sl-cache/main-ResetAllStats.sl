#line 1 "sub main::ResetAllStats"
package main; sub ResetAllStats {
     %OldStats = ();
     %AllStats = ();
     %OldScoreStats = ();
     %AllScoreStats = ();
     $AllStats{starttime} = time;
     unlink("$base/asspstats.sav.bak");
     unlink("$base/asspscorestats.sav.bak");
     rename("$base/asspstats.sav","$base/asspstats-".timestring('','','YYYY-MM-DD-hh-mm-ss').'.sav');
     rename("$base/asspscorestats.sav","$base/asspscorestats-".timestring('','','YYYY-MM-DD-hh-mm-ss').'.sav');
     ResetStats();
}
