#line 1 "sub main::ThreadStatus"
package main; sub ThreadStatus {
    my $Iam = shift;
    while ( my ($c,$v) = each %Con) {
      return unless $ThreadsDoStatus;
      if (($Con{$c}->{type} eq 'C' || $Con{$c}->{isreport}) && ! $Con{$c}->{movedtossl}) {
        my $fno = $Con{$c}->{fno} ;
        $ConFno{$fno} = &share({}) if (! exists $ConFno{$fno});
        threads->yield;
        eval{$ConFno{$fno}->{timestart} = $Con{$c}->{timestart};};
        eval{$ConFno{$fno}->{timelast} = $Con{$c}->{timelast};};
        eval{$ConFno{$fno}->{helo} = $Con{$c}->{helo};};
        eval{$ConFno{$fno}->{mailfrom} = $Con{$c}->{mailfrom};};
        eval{$ConFno{$fno}->{rcpt} = $Con{$c}->{rcpt};};
        eval{$ConFno{$fno}->{lastcmd} = $Con{$c}->{lastcmd};};
        eval{$ConFno{$fno}->{relayok} = $Con{$c}->{relayok};};
        eval{$ConFno{$fno}->{ip} = $Con{$c}->{ip};};
        eval{$ConFno{$fno}->{spamfound} = $Con{$c}->{spamfound};};
        eval{$ConFno{$fno}->{maillength} = $Con{$c}->{maillength};};
        eval{$ConFno{$fno}->{messagescore} = $Con{$c}->{messagescore};};
        eval{$ConFno{$fno}->{worker} = $Iam;};
        eval{$ConFno{$fno}->{ssl} = $Con{$c}->{oldfh} ? '*' : '_' ;};
        eval{$ConFno{$fno}->{friendssl} = $Con{$Con{$c}->{friend}}->{oldfh} ? '*' : '_' ;};
        eval{$ConFno{$fno}->{damping} = $Con{$c}->{damping};};
        eval{$ConFno{$fno}->{noprocessing} = $Con{$c}->{noprocessing};};
        eval{$ConFno{$fno}->{whitelisted} = $Con{$c}->{whitelisted};};
        eval{$ConFno{$fno}->{headerpassed} = $Con{$c}->{headerpassed};};
        eval{$ConFno{$fno}->{isreport} = $Con{$c}->{isreport};};
      }
    }
    threads->yield();
}
