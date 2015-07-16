#line 1 "sub main::ConCountSync"
package main; sub ConCountSync {
     my $count = 0;
     for (my $i = 1; $i<=$NumComWorkers; $i++) {
         $count += $ComWorker{$i}->{numActCon};
         last if $count;
     }
     if ($count == 0) {
        %SMTPSessionIP = ();
        threads->yield;
        $SMTPSessionIP{Total} = 0;
        threads->yield;
        $smtpConcurrentSessions = 0;
        threads->yield;
     }
}
