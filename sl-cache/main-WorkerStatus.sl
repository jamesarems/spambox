#line 1 "sub main::WorkerStatus"
package main; sub WorkerStatus {
     my %status = ();
     for (my $i = 1; $i<=$NumComWorkers; $i++) {
         $status{$i}{lastloop} = int(time - $WorkerLastAct{$i});
         $status{$i}{lastaction} = $lastd{$i};
     }
     if (exists $ConfigAdd{'NumComWorkers'}) {
         for (my $i = $NumComWorkers+1; $i<=$ConfigAdd{'NumComWorkers'}; $i++) {
             $status{$i}{lastloop} = 0;
             $status{$i}{lastaction} = 'NumComWorkers increased - assp restart required';
         }
     }
     $status{10000}{lastloop} = int(time - $WorkerLastAct{10000});
     $status{10000}{lastaction} = $lastd{10000};
     $status{10001}{lastloop} = int(time - $WorkerLastAct{10001});
     $status{10001}{lastaction} = $lastd{10001};
     return %status;
}
