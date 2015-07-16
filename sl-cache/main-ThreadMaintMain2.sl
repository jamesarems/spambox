#line 1 "sub main::ThreadMaintMain2"
package main; sub ThreadMaintMain2 {
    my $Iam = $WorkerNumber;
    return 0 if $Iam != 10000;
    return 0 if $isRunTMM2;
    $isRunTMM2 = 1;
    my $wasrun;
    my $l = $lastd{$Iam};
# database connection check is done independent from any time values
# the complete check for all tables should never take more than 0.05 seconds if all is ok
    if (($CanUseTieRDBM or $CanUseBerkeleyDB) && $DBisUsed && time >= $nextDBcheck) { # check - do we have lost any DB connection
                                       # and reconnect if possible
        my $cdbstime=Time::HiRes::time(); # to get the check time
        my $cdberror=&checkDBCon(time + $ThreadsWakeUpInterval + 2);      # or switch to files
        my $cdbetime=sprintf("%.3f",(Time::HiRes::time()) - $cdbstime); # to get the check time
        d("info: database connection was checked in $cdbetime seconds");
        mlog(0,"info: '$DBusedDriver' database connection was checked in $cdbetime seconds for all tables") if $MaintenanceLog > 2 && $DBusedDriver ne 'BerkeleyDB';
        mlog(0,"warning: $WorkerName - check the '$DBusedDriver' database connections has taken $cdbetime seconds (max=1.000s)") if ($cdbetime>1 && ! $cdberror); #0.1s is ok
        &ThreadYield();
        $lastd{$Iam} = $l;
    }

    if(time >= $nextDNSCheck) {
        d('updateDNS - call2');
        $nextDNSCheck = time + 60;
        $lastDNScheck = time;
        updateDNS( 'DNSServers', $Config{DNSServers}, $Config{DNSServers}, '' );
    }

    $wasrun = processMaintCMDQueue();

    if ($CanUseEMS && $resendmail && time >= $nextResendMail) {
        mlog(0,"info: looking for files to (re)send") if $MaintenanceLog >= 2;
        $nextResendMail = time + 300;
        d('ThreadMaintMain - resend_mail');
        &resend_mail();
        $wasrun = 1;
        &ThreadYield();
        $lastd{$Iam} = $l;
    }
    if(! $ComWorker{$Iam}->{run} || $doShutdownForce || $doShutdown) {$isRunTMM2 = 0; return $wasrun ;}

    if ($NextConfigReload && time >= $NextConfigReload) {
        $NextConfigReload = 0;
        $lastd{$Iam} = $l;
        $ConfigChanged = 1;
        $wasrun = 1;
    }
    if(! $ComWorker{$Iam}->{run}) {$isRunTMM2 = 0; return $wasrun ;}

    if (! $allIdle && scalar keys %ScheduledTask) {
        foreach my $task (sort keys %ScheduledTask) {
            next if (eval{$ScheduledTask{$task}->{Nextrun} >= time;});
            $wasrun = 1;
            $ScheduledTask{$task}->{Run}->($ScheduledTask{$task}->{Parm});
            &ThreadYield();
            my $nextsched = getNextSched($ScheduledTask{$task}->{Schedule},$ScheduledTask{$task}->{Desc});
            if ($nextsched >= time) {
                $ScheduledTask{$task}->{Nextrun} = $nextsched;
                $nextsched = timestring($nextsched);
                mlog(0,"info: rescheduled task : $ScheduledTask{$task}->{Desc} - to : $ScheduledTask{$task}->{Parm} - at : $ScheduledTask{$task}->{Schedule} - next run is at : $nextsched") if $MaintenanceLog > 1;
            } else {
                delete $ScheduledTask{$task};
                mlog(0,"error: removed scheduled task : $ScheduledTask{$task}->{Desc} - to : $ScheduledTask{$task}->{Parm} - at : $ScheduledTask{$task}->{Schedule} - calculated schedule is in the past");
            }
        }
        $lastd{$Iam} = $l;
    }
    if(! $ComWorker{$Iam}->{run}) {$isRunTMM2 = 0; return $wasrun ;}

    if (! $DisableSMTPNetworking && ! $reachedSMTPlimit && $POP3Interval && time >= $NextPOP3Collect) {
        mlog(0,"info: starting POP3 collection") if $MaintenanceLog >= 2;
        $wasrun = &POP3Collect();
        ScheduleMapSet('POP3Interval');
        $lastd{$Iam} = $l;
    }
    if(! $ComWorker{$Iam}->{run}) {$isRunTMM2 = 0; return $wasrun ;}

    if ($enableCFGShare && $CanUseNetSMTP && $isShareMaster && time >= $NextSyncConfig) {
        my $i = 0;
        my $wr = 0;
        for my $idx (0...$#ConfigArray) {
            my $c = $ConfigArray[$idx];
            last if(! $ComWorker{$Iam}->{run});
            next if ( ! $c->[0] || @{$c} == 5);
            next if $ConfigSync{$c->[0]}->{sync_cfg} != 1;
            my $stat = &syncGetStatus($c->[0]);
            next if($stat < 1 or $stat == 2);
            $wr += &syncConfigSend($c->[0]);
            ++$i > 10 and last;
        }
        $NextSyncConfig = time + ($wr ? 30 : 60);
        &ThreadYield();
        $wasrun |= $wr;
        $lastd{$Iam} = $l;
    }
    if(! $ComWorker{$Iam}->{run}) {$isRunTMM2 = 0; return $wasrun ;}

    if ($RunTaskNow{ExportMysqlDB} == 10000 && ! $ExportIsRunning) {
        d('ThreadMaintMain - ExportMysqlDB - export');
        $ExportIsRunning = 1;
        &exportMysqlDB('export');
        $ExportIsRunning = 0;
        $RunTaskNow{ExportMysqlDB} = '';
        mlog(0,'INFO: EXPORT removed from queue');
        &ThreadYield();
        $wasrun = 1;
        $lastd{$Iam} = $l;
    }
    if(! $ComWorker{$Iam}->{run}) {$isRunTMM2 = 0; return $wasrun ;}

    if ($RunTaskNow{ImportMysqlDB} == 10000) {
        d('ThreadMaintMain - ImportMysqlDB');
        &importMysqlDB();
        $RunTaskNow{ImportMysqlDB} = '';
        mlog(0,'INFO: IMPORT removed from queue');
        &ThreadYield();
        $wasrun = 1;
        $lastd{$Iam} = $l;
    }
    if(! $ComWorker{$Iam}->{run}) {$isRunTMM2 = 0; return $wasrun ;}

    if ($RunTaskNow{fillUpImportDBDir} == 10000) {
        d('ThreadMaintMain - fillUpImportDBDir');
        &importFillUp($RunTaskNow{fillUpImportDBDir});
        mlog(0,'INFO: fillUpImportDBDir removed from queue');
        $RunTaskNow{fillUpImportDBDir} = '';
        &ThreadYield();
        $wasrun = 1;
        $lastd{$Iam} = $l;
    }
    if(! $ComWorker{$Iam}->{run}) {$isRunTMM2 = 0; return $wasrun ;}

    if (($CanUseLDAP or $CanUseNetSMTP) && $ldaplistdb && ($RunTaskNow{forceLDAPcrossCheck} == 10000 or ($LDAPcrossCheckInterval && time >= $nextLDAPcrossCheck && ! $allIdle))) {
        ScheduleMapSet('LDAPcrossCheckInterval');
        d('ThreadMaintMain - forceLDAPcrossCheck');
        $RunTaskNow{forceLDAPcrossCheck} = 10000;
        if (!$mysqlSlaveMode) {
            &LDAPcrossCheck();
            $wasrun = 1;
        }
        $RunTaskNow{forceLDAPcrossCheck} = '';
        mlog(0,'INFO: LDAP/VRFY-CrossCheck removed from queue');
        &ThreadYield();
        $lastd{$Iam} = $l;
    }
    if(! $ComWorker{$Iam}->{run}) {$isRunTMM2 = 0; return $wasrun ;}

    if ($RunTaskNow{BlockReportNow} == 10000) {
        d('BlockReportGen - now');
        mlog(0,"info: got request to run 'BlockReportNow'") if $MaintenanceLog;
        &BlockReportGen("1");
        $RunTaskNow{BlockReportNow} = '';
        $wasrun = 1;
        &ThreadYield();
        $lastd{$Iam} = $l;
    }
    if(! $ComWorker{$Iam}->{run}) {$isRunTMM2 = 0; return $wasrun ;}

    $isRunTMM2 = 0;
    return $wasrun;
}
