#line 1 "sub main::ThreadRebuildSpamDBMain"
package main; sub ThreadRebuildSpamDBMain {
    my $Iam = $WorkerNumber;
    $StartRebuild = 1;
    my ($mcount, $minutes) = split(/\s+/o,$newReportedInterval);
    my $nowRebuildSchedule = $RebuildSchedule;
    my $nowReStartSchedule = $ReStartSchedule;
    $WorkerLastAct{$Iam} = time;
    $itime=Time::HiRes::time(); # loop cycle idle end time

    if (! $ComWorker{$Iam}->{isstarted}) {
        $ComWorker{$Iam}->{isstarted} = 1;
        if (! &write_rebuild_module($ComWorker{$Iam}->{rb_version})) {
            mlog(0,"error: unable to create $base/lib/rebuildspamdb.pm module - $!");
        }
        sleep 5;
        $ThreadIdleTime{$Iam} += 5;
        threads->yield();
    }

    if ($doShutdownForce || $doShutdown != 0) {
        sleep 1;
        $ThreadIdleTime{$Iam} += 1;
        threads->yield();
        return;
    }
    return if ! $ComWorker{$Iam}->{run};

    if ($ComWorker{$Iam}->{rereadconfig} && $ComWorker{$Iam}->{rereadconfig} <= time) {
        &ThreadReReadConfig($Iam);
        &ThreadYield();
        return;
    }

    if($spamdb && $RunTaskNow{RunRebuildNow} == 10001) {
        &runRebuild();
        $nextRebuildSpamDB = isSched($RebuildSchedule) ? getSchedTime('RebuildSchedule') : 0;
        $RunTaskNow{RunRebuildNow} = '';
        mlog(0,"INFO: RebuildSpamdb removed from queue");
    }

    if ($allIdle) {
        sleep 1;
        $ThreadIdleTime{$Iam} += 1;
        return;
    }

    if (($spamdb && $CanUseSchedCron && $RebuildSchedule !~ /noschedule/io ) or
        ($ReStartSchedule && $CanUseSchedCron)
       )
    {
        d('schedule waiting');
        my $cron = Schedule::Cron->new(
            sub{
                $ThreadIdleTime{$Iam} += 5;
                my $t = Time::HiRes::time();
                if ($RunTaskNow{RunRebuildNow} == 10001) {
                    &runRebuild();
                    mlog(0,"INFO: RebuildSpamdb removed from queue");
                    d('schedule waiting');
                    $WorkerLastAct{$Iam} = time;
                    die "harmless\n";
                }
                die "harmless\n" if (! $ComWorker{$WorkerNumber}->{run} || $allIdle);
                if ($ComWorker{$WorkerNumber}->{rereadconfig} && $ComWorker{$WorkerNumber}->{rereadconfig} <= time) {
                    &ThreadReReadConfig($Iam);
                    $WorkerLastAct{$Iam} = time;
                    d('schedule waiting');
                    die "harmless\n" if (($nowRebuildSchedule ne $RebuildSchedule) || ($nowReStartSchedule ne $ReStartSchedule));
                }
                $WorkerLastAct{$Iam} = time if manualCorrected();
                my $h = scalar(keys(%newReported));
                if ($minutes && $h && ($h >= $mcount || time > $nextNewReported)) {
                    $t -= &rebuildAddCorrections();
                    $nextNewReported = time + $minutes * 60;
                } elsif (time > $nextNewReported) {
                    $nextNewReported = time + $minutes * 60;
                    my $mem = $showMEM ? printMem() : 0;
                    mlog(0,"info: worker memory$mem") if $mem && $MaintenanceLog > 2;
                }
                &processMaintCMDQueue();
                threads->yield();
                $ThreadIdleTime{$Iam} -= Time::HiRes::time() - $t;
                d('schedule waiting');
                return;
            },{processprefix => "$perl $assp"});
        $cron->add_entry("* * * * * 0-59/5");
        $StartRebuild = 0;
        my $nextRebuild;
        my $nextRestart;
        if ($spamdb && $RebuildSchedule !~ /noschedule/io) {
            for (split/\|/o,$RebuildSchedule) {$cron->add_entry($_,\&runRebuild)};
            $nextRebuild = getNextSched($RebuildSchedule,'RebuildSpamdb Scheduler') || '';
            $nextRebuild = ' - next RebuildSpamdb is scheduled for '.timestring($nextRebuild) if $nextRebuild;
        }
        if ($ReStartSchedule && $ReStartSchedule !~ /noschedule/io) {
            for (split/\|/o,$ReStartSchedule) {$cron->add_entry($_,\&schedShutdown);}
            $nextRestart = getNextSched($ReStartSchedule,'ReStart Scheduler') || '';
            $nextRestart = ' - next ASSP-ReStart is scheduled for '.timestring($nextRestart) if $nextRestart;
        }

        mlog(0,"info: starting RebuildSpamdb Scheduler with '$RebuildSchedule'$nextRebuild") if($ScheduleLog && $spamdb && $RebuildSchedule !~ /noschedule/io);
        mlog(0,"info: starting ReStart Scheduler with '$ReStartSchedule'$nextRestart") if($ScheduleLog && $ReStartSchedule !~ /noschedule/io);
        $StartRebuild = 1;
        eval{$cron->run(nofork => 1,skip => 1, log => \&schedlog, detach => 0, nostatus => 1);};
        mlog(0,"error: $@") if ($@ && $@ !~ /harmless/io);
        &ThreadYield();
        mlog(0,"info: RebuildSpamdb Scheduler stopped") if($ScheduleLog && $RebuildSchedule !~ /noschedule/io);
        mlog(0,"info: ReStart Scheduler stopped") if($ScheduleLog && $ReStartSchedule !~ /noschedule/io);
        return;
    }
    
    &ThreadYield();
    my $t = 1 - processMaintCMDQueue();
    manualCorrected();
    my $h = scalar(keys(%newReported));
    if ($minutes && $h && ($h >= $mcount || time > $nextNewReported)) {
        $t -= &rebuildAddCorrections();
        $nextNewReported = time + $minutes * 60;
    } elsif (time > $nextNewReported) {
        $nextNewReported = time + $minutes * 60;
    }
    $t = 0 if $t < 0;
    $t *= 6;
    d("idle loop ($t s)");
    if ($t) {
        sleep $t;
        $ThreadIdleTime{$Iam} += $t;
    }
}
