#line 1 "sub main::ThreadMain2"
package main; sub ThreadMain2 {
    my $sfh = shift;
    my $Iam = $WorkerNumber;
    return if $Iam >= 10000; # only for SMTP-Workers
    return if $Iam == 0; # only for SMTP-Workers
    return if(! $ComWorker{$Iam}->{run});
    return if ($nextThreadMain2 > Time::HiRes::time());
    return if $ThreadMain2Act;
    $nextThreadMain2 = Time::HiRes::time() + 1;
    $WorkerLastAct{$Iam} = time;
    $ThreadMain2Act = 1;
    my @canread;
    my @canwrite;
    &sigoff(__LINE__);
    &ConDone();
    &ThreadGetNewCon();
    &ConDone();
    &ThreadReReadConfig($Iam) if ($ComWorker{$Iam}->{rereadconfig} && $ComWorker{$Iam}->{rereadconfig} <= time);
    &sigon(__LINE__);
    &ThreadStatus($Iam) if ($ThreadsDoStatus);
    return if(! $ComWorker{$Iam}->{run});
# database connection check is done independent from any time values
# the complete check for all tables should never take more than 0.05 seconds if all is ok
    my $itime=$CanStatCPU ? (Time::HiRes::time()) : time; # loop cycle idle end time
    if (($CanUseTieRDBM or $CanUseBerkeleyDB) && $DBisUsed && $itime >= $nextDBcheck) { # check - do we have lost any DB connection
                                    # and reconnect if possible
        my $cdbstime=Time::HiRes::time(); # to get the check time
        my $cdberror=&checkDBCon(int($itime) + 90);                                # or switch to files
        my $cdbetime=sprintf("%.3f",(Time::HiRes::time()) - $cdbstime); # to get the check time
        d("info: database connection was checked in $cdbetime seconds");
        mlog(0,"warning: $WorkerName - check the database connections has taken $cdbetime seconds (max=1.000s)") if ($cdbetime>1 && ! $cdberror); #0.1s is ok
    }

    my $wait=$pollwait;
    &sigoff(__LINE__);
    my $stime=Time::HiRes::time(); # loop cycle start time

    my $re;
    if ($readable->handles()) {
        if ($IOEngineRun == 0) {
            $re = $readable->poll($wait);
            @canread = $readable->handles(POLLIN|POLLHUP) if $re > 0;
        } else {
            @canread = $readable->can_read($wait);
            $re = @canread;
        }
        if ($re > 0) {
            $wait = $MinPollTimeT/1000;
        } elsif ($re == 0) {
            $wait = 1;
            &ThreadYield();
        } else {
            if ($IOEngineRun == 0) {
                my $err = &pollerror($readable);
                $wait = $err >= scalar(@canread) ? 1 : $MinPollTimeT/1000;    # wait at least two milliseconds
                &ThreadYield();
            }
        }
    }

    my $wr;
    if ($writable->handles()) {
        if ($IOEngineRun == 0) {
            $wr = $writable->poll($wait);
            @canwrite = $writable->handles(POLLOUT|POLLHUP) if $wr > 0;
        } else {
            @canwrite = $writable->can_write($wait);
            $wr = @canwrite;
        }
        if ($wr > 0) {
            $pollwait = $MinPollTimeT/1000;                 # wait at least two milliseconds
        } elsif ($wr == 0) {
            $pollwait = $wait;
            &ThreadYield() if $wait == 1;
        } else {
            if ($IOEngineRun == 0) {
                &pollerror($writable);
                $pollwait = $wait;
                &ThreadYield() if $wait == 1;
            }
        }
    }

    $itime=Time::HiRes::time(); # loop cycle idle end time
    &sigon(__LINE__);
    &ThreadYield();
    my $ptime = $itime - $stime;
    $ThreadIdleTime{$Iam} += $ptime;
    mlog(0,"warning: the operating system socket poll cycle has taken $ptime seconds - this is very much is too long")
        if ($ConnectionLog >= 2 and $ptime > 3);

    while (@canwrite) {
        my $fh = shift @canwrite;
        return if(! $ComWorker{$Iam}->{run});
        next if("$fh" eq "$sfh");
        next unless(fileno($fh));
        $ThreadDebug = $Con{$fh}->{debug};
        my $l=length($Con{$fh}->{outgoing});
        d("$fh $Con{$fh}->{ip} l=$l");
        if($l) {
            $thread_nolog = 0;
            $fh->blocking(0) if $fh->blocking;
            &sigoff(__LINE__);
            my $written=$fh->syswrite($Con{$fh}->{outgoing},$l);
            my $werr = $!;
            &sigon(__LINE__);
            if (!$written && $werr) {
                mlog($fh,"warning: $fh got writeerror - $werr") if $ConnectionLog >= 2;
            }
            if($debug or $ThreadDebug) {
                d("wrote: $Con{$fh}->{ip} ($written)<".substr($Con{$fh}->{outgoing},0,$written).">");
            }
            $Con{$fh}->{lastwritten} = time;
            my $m = &timestring();
            if ($Con{$fh}->{type} eq 'C'){
              $Con{$fh}->{contimeoutdebug} .= "$m client wrote = ".substr($Con{$fh}->{outgoing},0,$written) if $ConTimeOutDebug;
            } else {
              $Con{$Con{$fh}->{friend}}->{contimeoutdebug} .= "$m server wrote = ".substr($Con{$fh}->{outgoing},0,$written) if $ConTimeOutDebug;
            }
            $Con{$fh}->{outgoing}=substr($Con{$fh}->{outgoing},$written);
            $l=length($Con{$fh}->{outgoing});

            # test for highwater mark
            if($written>0 && $l < $OutgoingBufSizeNew && $Con{$fh}->{paused}) {
                $Con{$fh}->{paused}=0;
                &dopoll($Con{$fh}->{friend},$readable,POLLIN) if ($Con{$fh}->{friend});
            }
        }
        if(length($Con{$fh}->{outgoing})==0) {
              unpoll($fh,$writable);
        }
        $ThreadDebug = 0;
    }
    &ThreadYield();
    while (@canread) {
        my $fh = shift @canread;
        return if(! $ComWorker{$Iam}->{run});
        next if("$fh" eq "$sfh");
        next unless(fileno($fh));
        if ($fh && $SocketCalls{$fh}) {
                $ThreadDebug = $Con{$fh}->{debug} if exists $Con{$fh};
                $thread_nolog = 0;
                $stime=Time::HiRes::time(); # loop cycle idle end time
                $SocketCalls{$fh}->($fh) if (! exists $ConDelete{$fh});
                $itime=Time::HiRes::time(); # loop cycle idle end time
                my $SocketCallTime = $itime - $stime;
                mlog($fh,"SC-Time $WorkerName: $SocketCallTime") if ($WorkerLog == 3);
                $ThreadDebug = 0;
        }
    }
    return if(! $ComWorker{$Iam}->{run});
    &sigoff(__LINE__);
    &ConDone();

    SMTPTimeOut($sfh);

    d('ThreadMain2 - end loop');
    &ConDone();
    &sigon(__LINE__);
    if (time > $nextdetectGhostCon) {
        &sigoff(__LINE__);
        &detectGhostCon();
        $nextdetectGhostCon = time + 300;
        &sigon(__LINE__);
    }
    $nextThreadMain2 = Time::HiRes::time() + 1;
    $ThreadMain2Act = 0;
}
