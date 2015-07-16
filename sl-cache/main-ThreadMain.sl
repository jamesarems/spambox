#line 1 "sub main::ThreadMain"
package main; sub ThreadMain {
    my $Iam = $WorkerNumber;
    $WorkerLastAct{$Iam} = time;
    my @canread;
    my @canwrite;
    my @selerr;
    my $numActCon;
    &sigoff(__LINE__);
    &ConDone();
    &ThreadGetNewCon();
    &NewSMTPConCall();
    &ConDone();
    $numActCon = $ComWorker{$Iam}->{numActCon};
    &sigon(__LINE__) if $HMM4ISP;
    &ThreadReReadConfig($Iam) if ($ComWorker{$Iam}->{rereadconfig} && $ComWorker{$Iam}->{rereadconfig} <= time);
    &sigon(__LINE__) unless $HMM4ISP;
    &ThreadStatus($Iam) if ($ThreadsDoStatus);
    return $numActCon if(! $ComWorker{$Iam}->{run});
# database connection check is done independent from any time values
# the complete check for all tables should never take more than 0.05 seconds if all is ok
    my $itime=Time::HiRes::time(); # loop cycle idle end time
    if (($CanUseTieRDBM or $CanUseBerkeleyDB) && $DBisUsed && $itime >= $nextDBcheck) { # check - do we have lost any DB connection
        my $cdbstime=Time::HiRes::time(); # to get the check time
        my $cdberror=&checkDBCon(int($itime) + 90);                                # or switch to files
        my $cdbetime= sprintf("%.3f",(Time::HiRes::time()) - $cdbstime) ; # to get the check time
        d("info: database connection was checked in $cdbetime seconds");
        mlog(0,"warning: $WorkerName - check the database connections has taken $cdbetime seconds (max=1.000s)") if ($cdbetime>1 && ! $cdberror); #0.1s is ok
    }

    $numActCon = $ComWorker{$Iam}->{numActCon};
    return 0 if ($numActCon == 0);

    my $wait = $pollwait;
    my $longwait = $EnableHighPerformance ? $MinPollTimeT/1000 : 1 ;
    &sigoff(__LINE__);
    my $stime=Time::HiRes::time(); # loop cycle start time

    my $re;
    my $rh;
    if ($rh = $readable->handles()) {
        if ($IOEngineRun == 0) {
            $re = $readable->poll($wait);
            @canread = $readable->handles(POLLIN|POLLHUP) if $re > 0;
        } else {
            @canread = $readable->can_read($wait);
            $re = @canread;
            @selerr = $readable->has_exception($MinPollTimeT/1000);
        }
        if ($re > 0) {
            $wait = $MinPollTimeT/1000;
        } elsif ($re == 0) {
            $wait = $longwait;
            &ThreadYield() if $wait == 1;
        }
        if ($re < 0 or @selerr) {
            &pollerror($readable);
            $wait = scalar(@canread) ? $MinPollTimeT/1000 : $longwait;    # wait at least two milliseconds
        }
    }
    d("rh: $rh - read: $re - wait: $wait");

    my $wr;
    my $wh;
    if ($wh = $writable->handles()) {
        if ($IOEngineRun == 0) {
            $wr = $writable->poll($wait);
            @canwrite = $writable->handles(POLLOUT|POLLHUP) if $wr > 0;
        } else {
            @canwrite = $writable->can_write($wait);
            $wr = @canwrite;
            @selerr = $writable->has_exception($MinPollTimeT/1000);
        }
        if ($wr > 0) {
            $pollwait = $MinPollTimeT/1000;                 # wait at least two milliseconds
        } elsif ($wr == 0) {
            $pollwait = $wait;
            &ThreadYield() if $wait == 1;
        }
        if ($wr < 0 or @selerr) {
            &pollerror($writable);
            $pollwait = scalar(@canwrite) ? $MinPollTimeT/1000 : $wait;    # wait at least two milliseconds
        }
    } else {
        $pollwait = $wait;
    }
    d("wh: $wh - write: $wr - wait: $pollwait");

    $itime=Time::HiRes::time(); # poll loop cycle idle end time
    &sigon(__LINE__);
    my $ptime = $itime - $stime;
    mlog(0,"warning: the operating system socket poll cycle has taken $ptime seconds - this is very much is too long")
        if ($ConnectionLog >= 2 and $ptime > 3);
    &ThreadYield();

    if (! $EnableHighPerformance && ($rh + $wh == 0)) {
        my $loop = 300;
        do {
            &ThreadYield();
        } while ! $ComWorker{$Iam}->{numActCon} && --$loop;
    } elsif ($rh + $wh == 0) {
        $pollwait = 1;
        sleep 1;
    }

    $ThreadIdleTime{$Iam} += Time::HiRes::time() - $stime;
    while (@canwrite) {
        my $fh = shift @canwrite;
        return $numActCon if(! $ComWorker{$Iam}->{run});
        next unless(fileno($fh));
        if (exists $Con{$fh}->{sendTime}) {
            next if $Con{$fh}->{sendTime} < time;
            delete $Con{$fh}->{sendTime};
        }
        $ThreadDebug = $Con{$fh}->{debug};
        my $l=length($Con{$fh}->{outgoing});
        d("$fh $Con{$fh}->{ip} l=$l");
        if($l) {
            $thread_nolog = 0;
            $fh->blocking(0) if $fh->blocking;
            &sigoff(__LINE__);
            my $written;
            eval{$written=$fh->syswrite($Con{$fh}->{outgoing},$l);};
            my $werr;
            $werr = ' - '.$!.' - '.$@ if $! or $@;
            &sigon(__LINE__);
            if (!$written && $werr) {
                mlog($fh,"warning: $fh got writeerror$werr",1) if $ConnectionLog > 1 && $Con{$fh}->{lastWriteError} ne $werr;
                $Con{$fh}->{lastWriteError} = $werr;
            } elsif (! $werr) {
                delete $Con{$fh}->{lastWriteError};
            }
            $Con{$fh}->{lastwritten} = time;
            if($debug or $ThreadDebug) {
                if ($debugNoWriteBody) {
                    d("wrote: $fh $Con{$fh}->{ip} ($written)$werr");
                } else {
                    d("wrote: $fh $Con{$fh}->{ip} ($written)<".substr($Con{$fh}->{outgoing},0,$written).">$werr");
                }
            }
            if ($ConTimeOutDebug) {
                my $m = &timestring();
                if ($Con{$fh}->{type} eq 'C'){
                  $Con{$fh}->{contimeoutdebug} .= "$m client wrote = ".substr($Con{$fh}->{outgoing},0,$written);
                } else {
                  $Con{$Con{$fh}->{friend}}->{contimeoutdebug} .= "$m server wrote = ".substr($Con{$fh}->{outgoing},0,$written);
                }
            }
            $Con{$fh}->{outgoing}=substr($Con{$fh}->{outgoing},$written);
            $l=length($Con{$fh}->{outgoing});

            # test for highwater mark
            if($written>0 && $l < $OutgoingBufSizeNew && $Con{$fh}->{paused}) {
                $Con{$fh}->{paused}=0;
                &dopoll($Con{$fh}->{friend},$readable,POLLIN) if (fileno($Con{$fh}->{friend}));
            }
            if ($Con{$fh}->{type} ne 'C' &&
                $written > 0 &&
                $Con{$fh}->{friend} &&
                exists $Con{$Con{$fh}->{friend}} &&
                $Con{$Con{$fh}->{friend}}->{lastcmd} =~ /^ *(?:DATA|BDAT)/io )
            {
                $Con{$Con{$fh}->{friend}}->{writtenDataToFriend} += $written;
            }
        }
        if(length($Con{$fh}->{outgoing})==0) {
              unpoll($fh,$writable);
        }
        done2($fh) if $Con{$fh}->{closeafterwrite};
        $ThreadDebug = 0;
    }

    &ThreadYield();
    while (@canread) {
        my $fh = shift @canread;
        return $numActCon if(! $ComWorker{$Iam}->{run});
        next unless(fileno($fh));
        &NewSMTPConCall();
        my $dampOffset = 0;
#        $dampOffset = $DoDamping * 10 if ! $Con{$fh}->{messagescore} && &pbBlackFind($Con{$fh}->{ip});
        my $damptime; $damptime = int(($Con{$fh}->{messagescore} + $dampOffset) / $DoDamping) if $DoDamping;
        $damptime = $damptime > 0 ? $damptime > $maxDampingTime ? $maxDampingTime : $damptime : 0;
        $damptime = 2 if ($damptime > 2 && lc $Con{$fh}->{lastcmd} eq 'data' && ! $Con{$fh}->{headerpassed});
        if ($DoDamping &&
            $DoPenalty &&
            $DoPenaltyMessage &&
            $damptime &&
            ! $reachedSMTPlimit &&
            ! $doShutdownForce &&
            ! $doShutdown > 0 &&
            ! $allIdle &&
            ! $Con{$fh}->{nodamping} &&
            $Con{$fh}->{type} eq 'C' &&
            ! $Con{$fh}->{headerpassed} &&
            ! $Con{$fh}->{relayok} &&
            ! $Con{$fh}->{ispip} &&
            ! $Con{$fh}->{whitelisted} &&
            ! $Con{$fh}->{red} &&
            ! $Con{$fh}->{noprocessing} &&
            ! $Con{$fh}->{contentonly} &&
            $ComWorker{$Iam}->{run} == 1 &&
#            ! $Con{$fh}->{nodelay} &&
            ! $Con{$fh}->{nopb} &&
            ! $Con{$fh}->{pbwhite}
        ) {
            if (! $Con{$fh}->{damping}) {
                mlog($fh,"info: start damping ($damptime s)",1) if $ConnectionLog ;
                $Stats{damping}++;
                $Con{$fh}->{damping} = 1;
            }
            if (time - $Con{$fh}->{timelast} < $damptime) {
                if (! $dampedFH{$fh}) {
                    $dampedFH{$fh} = $fh;
                    unpoll($fh,$readable);
                    next;
                }
            } else {
                $Stats{damptime} += $damptime;
                $Con{$fh}->{damptime} += $damptime;
            }
        }

        if ($fh && $SocketCalls{$fh}) {
                $ThreadDebug = $Con{$fh}->{debug} if exists $Con{$fh};
                $thread_nolog = 0;
                $stime=Time::HiRes::time(); # loop cycle idle end time
                $SocketCalls{$fh}->($fh) if (! exists $ConDelete{$fh});
                $itime=Time::HiRes::time(); # loop cycle idle end time
                my $SocketCallTime = $itime - $stime;
                mlog($fh,"SC-Time $WorkerName: $SocketCallTime",1) if ($WorkerLog == 3);
                $ThreadDebug = 0;
        }
    }
    return $numActCon if(! $ComWorker{$Iam}->{run});
    &sigoff(__LINE__);# if ($ComWorker{$WorkerNumber}->{CANSIG} == 1);
    &ConDone();

    &SMTPTimeOut();

    d('ThreadMain - end loop');
    &ConDone();
    &sigon(__LINE__);
    while ( my ($fh,$dfh) = each %dampedFH) {
        if (! $fh || ! $dfh || ! fileno($dfh)) {
            delete $dampedFH{$fh};
            next;
        }
        my $dampOffset = 0;
#        $dampOffset = $DoDamping * 10 if ! $Con{$fh}->{messagescore} && &pbBlackFind($Con{$fh}->{ip});
        my $damptime; $damptime = int(($Con{$fh}->{messagescore} + $dampOffset) / $DoDamping) if $DoDamping;
        $damptime = $damptime > 0 ? $damptime > $maxDampingTime ? $maxDampingTime : $damptime : 0;
        $damptime = 2 if ($damptime > 2 && lc $Con{$fh}->{lastcmd} eq 'data' && ! $Con{$fh}->{headerpassed});
        if ($doShutdownForce ||
            $doShutdown > 0 ||
            $allIdle ||
            $Con{$fh}->{nodamping} ||
            ! $DoDamping ||
            ! $DoPenalty ||
            ! $DoPenaltyMessage ||
            $reachedSMTPlimit ||
            time - $Con{$fh}->{timelast} >= $damptime ||
            $ComWorker{$Iam}->{run} != 1
           )
        {
            &dopoll($dfh,$readable,POLLIN);
            delete $dampedFH{$fh};
            mlog($fh,"info: damping - stolen $damptime seconds",1) if $ConnectionLog >= 2 ;
        }
    }
    if (time > $nextdetectGhostCon) {
        &sigoff(__LINE__);
        &detectGhostCon();
        $nextdetectGhostCon = time + 300;
        &sigon(__LINE__);
    }
    return $numActCon;
}
