#line 1 "sub main::getStuckWorker"
package main; sub getStuckWorker {
     my $now = time;
     my $lastworker = 0;
     my $last = 0;
     my $act;
     for (my $i = 1; $i<=$NumComWorkers; $i++) {
         $act = $WorkerLastAct{$i};
         next if (! $act
                  || $ComWorker{$i}->{issleep} == 1
                  || ! $ComWorker{$i}->{run}
                  || $ComWorker{$i}->{inerror} == 1);
         if ($last < $act) {
             $lastworker = $i;
             $last = $act;
         }
         my $dif = $now - $act;
         if($dif > 180) {
             mlog(0,"info: Loop in Worker_$i was not active for $dif seconds");
             mlog(0,"info: Worker_$i : $lastsigoff{$i}");
             mlog(0,"info: Worker_$i : $lastsigon{$i}");
             mlog(0,"info: Worker_$i : last action was : ".substr($lastd{$i},0,25) );
             mlog(0,"warning: try to terminate inactive/stucking Worker_$i");
             $ComWorker{$i}->{inerror} = 1;
             $Threads{$i}->kill('TERM');
         }
     }
     return $lastworker,$act;
}
