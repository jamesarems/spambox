#line 1 "sub main::ConDone"
package main; sub ConDone {
    my %isDamping = ();
    while ( my ($con,$v) = each %ConDelete) {
        my $dampOffset = 0;
#        $dampOffset = $DoDamping * 10 if ! $Con{$con}->{messagescore} && &pbBlackFind($Con{$con}->{ip});
        my $damptime ;$damptime = int(($Con{$con}->{messagescore} + $dampOffset) / $DoDamping) if $DoDamping;
        $damptime = $damptime > 0 ? $damptime > $maxDampingTime ? $maxDampingTime : $damptime : 0;
        if ($DoDamping &&
            $DoPenalty &&
            $DoPenaltyMessage &&
            $damptime &&
            ! $reachedSMTPlimit &&
            ! $doShutdownForce &&
            ! $doShutdown > 0 &&
            ! $allIdle &&
            ! $Con{$con}->{nodamping} &&
            $Con{$con}->{type} eq 'C' &&
            ! $Con{$con}->{relayok} &&
            ! $Con{$con}->{ispip} &&
            ! $Con{$con}->{whitelisted} &&
            ! $Con{$con}->{red} &&
            ! $Con{$con}->{noprocessing} &&
            ! $Con{$con}->{contentonly} &&
            $ComWorker{$WorkerNumber}->{run} == 1 &&
#            ! $Con{$con}->{nodelay} &&
            ! $Con{$con}->{nopb} &&
            ! $Con{$con}->{pbwhite}
        ) {
            if (! $Con{$con}->{damping}) {
                mlog($con,"info: start damping on closing connection ($damptime)",1) if $ConnectionLog ;
                $Stats{damping}++;
                $Con{$con}->{damping} = 1;
            }
            $isDamping{$con} = $ConDelete{$con};
            next if time - $Con{$con}->{timelast} < $damptime;
        }
        $Stats{damptime} += $damptime if $Con{$con}->{damping};
        $Con{$con}->{damptime} += $damptime if $Con{$con}->{damping};
        $ConDelete{$con}->($con) if $con;
    }
    %ConDelete = %isDamping;
    undef %ConDelete unless keys %ConDelete;
    if ($WorkerNumber > 0 and $WorkerNumber < 10000) {
        my $n = scalar(keys %SocketCalls);
        $ComWorker{$WorkerNumber}->{numActCon} = int(($n+1)/2);      # set the number of active connection in thread
    }
    if (time > $nextConSync && $WorkerNumber == 0) {
        &ConCountSync();
        $nextConSync = time + 60;
    }
}
