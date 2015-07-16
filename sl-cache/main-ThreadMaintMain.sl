#line 1 "sub main::ThreadMaintMain"
package main; sub ThreadMaintMain {
    my $Iam = $WorkerNumber;
    my $wasrun = 0;
    $WorkerLastAct{$Iam} = time;
    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime(time);
    undef %Con unless keys(%Con);
    &ThreadReReadConfig($Iam) if ($ComWorker{$Iam}->{rereadconfig} && $ComWorker{$Iam}->{rereadconfig} <= time);
    if (! $ComWorker{$Iam}->{isstarted}) {
        my $gripcount;
        if ($griplist && $GriplistDriver eq 'orderedtie') {
            $gripcount = scalar keys %{$GriplistObj->{cache}};
        } else {
            $gripcount = BDB_getRecordCount('Griplist');
        }
        $ComWorker{$Iam}->{isstarted} = 1;
        %WhiteOrgList = ();
        d('build WhiteOrgList from Senderbase-Cache');
        while (my ($k,$v)=each(%SBCache)) {    # load WhiteOrgList from SBCache
            if ($v !~ /\!/o or $k !~ /\//o) {
                delete $SBCache{$k};
                next;
            }
            my ( $ct, $status, $data ) = split( /!/o, $v );
            my ( $ipcountry, $orgname, $domainname, $blacklistscore, $hostname_matches_ip, $ipCIDR , $hostname) = split( /\|/o, $data ) ;
            $WhiteOrgList{lc $domainname} = $orgname if ($status == 2 && $domainname && $orgname);
        }
        &cleanCachePersBlack();
        mlog(0,"info: last full Griplist download was at: " .  timestring($Griplist{'255.255.255.255'}))  if $MaintenanceLog && exists $Griplist{'255.255.255.255'};
        mlog(0,"info: last delta Griplist download was at: " . timestring($Griplist{'255.255.255.254'})) if $MaintenanceLog && exists $Griplist{'255.255.255.254'};
        $NextGriplistDownload = ($Griplist{'255.255.255.254'} + 3550 > time + 180) ? $Griplist{'255.255.255.254'} + 3550 : time + 180;
        $NextGriplistDownload = time + 60 unless $gripcount;
        $NextDroplistDownload = time + 150;
        my ($file) = $TLDS =~ /^ *file: *(.+)/io;
        $NextTLDlistDownload = time + 120 if (-e "$base/$file");
        $NextBackDNSFileDownload = time + 300;
        $NextVersionFileDownload = time + 60;
        $NextSPAMBOXFileDownload = time + 90;
        $NextSyncConfig = time + 60;
        $nextStatsUpload = $Stats{nextUpload};
        ScheduleMapSet('GroupsReloadEvery');
        ScheduleMapSet('POP3Interval');
        ($file) = $localBackDNSFile =~ /^ *file: *(.+)/io;
        if ($file && $DoBackSctr && $downloadBackDNSFile) {
            $file = "$base/$file";
            $FileUpdate{"$file".'localBackDNSFile'} = ftime($file);
        }
        my $spambox = $spambox;
        $spambox =~ s/\\/\//go;
        $spambox = $base.'/'.$spambox if ($spambox !~ /\Q$base\E/io);
        if (-e $spambox) {
            $FileUpdate{"$spambox".'spamboxCode'} = ftime($spambox);
            mlog(0,"info: watching the running script '$spambox' for changes")
              if ($AutoRestartAfterCodeChange && ($AsAService || $AsADaemon || $AutoRestartCmd));
        } elsif ($AutoRestartAfterCodeChange) {
            mlog(0,"warning: unable to find running script '$spambox' for 'AutoRestartAfterCodeChange'")
              if ($AsAService || $AsADaemon || $AutoRestartCmd);
        }
    }

    if ($doShutdownForce || $doShutdown > 0 || $allIdle) {
        unless (&ThreadMaintMain2($Iam)) {sleep 1; $ThreadIdleTime{$WorkerNumber} += 1;}
        return;
    }
    return if(! $ComWorker{$Iam}->{run});

    my $isRunTask;
    foreach (keys %RunTaskNow) {
        $isRunTask ||= $RunTaskNow{$_} if $RunTaskNow{$_} != 10000;
        threads->yield();
    }
    if (! $isRunTask && $doShutdown < 0) {
        mlog(0,"info: spambox has finished all running tasks after a scheduled restart was requested - initialize automatic restart for SPAMBOX in 15 seconds");
        $doShutdown = time + 15;
        mlog(0,"info: damping is now switched off until spambox is down") if $DoDamping;
        return;
    }

    &ThreadMaintMain2($Iam);

    my $lspambox = $spambox;
    $lspambox =~ s/\\/\//go;
    $lspambox = $base.'/'.$lspambox if ($lspambox !~ /\Q$base\E/io);
    if ((lc $AutoRestartAfterCodeChange eq 'immed' ||
        ( $AutoRestartAfterCodeChange && $codeChanged && $hour == $AutoRestartAfterCodeChange)) &&
        ($AsAService || $AsADaemon || $AutoRestartCmd) &&
        ! $isRunTask &&
        ! $doShutdown &&
        ! $allIdle &&
        $NextCodeChangeCheck < time &&
        -e "$lspambox" &&
        fileUpdated($lspambox,'spamboxCode')
       )
    {
        $FileUpdate{"$lspambox".'spamboxCode'} = ftime($lspambox);
        mlog(0,"info: new '$lspambox' script detected - performing syntax check on new script");
        my $cmd;
        if ($^O eq "MSWin32") {
            $cmd = '"' . $perl . '"' . " -c \"$lspambox\" 2>&1";
        } else {
            $cmd = '\'' . $perl . '\'' . " -c \'$lspambox\' 2>&1";
        }
        my $res = qx($cmd);
        if ($res =~ /syntax\s+OK/ios) {
            if ($res !~ /SPAMBOX\s+\Q$MajorVersion\E/ios) {
                mlog(0,"error: autoupdate: the version of '$lspambox' is not an SPAMBOX major version $MajorVersion - restoring current running script $MAINVERSION!");
                copy($lspambox.'.run',"$lspambox") && ($FileUpdate{"$lspambox".'spamboxCode'} = ftime($lspambox));
            } else {
                mlog(0,"info: new '$lspambox' script detected - syntax check returned OK - requesting automatic restart for SPAMBOX in 15 seconds");
                $doShutdown = -1;
            }
        } else {
            mlog(0,"error: new '$lspambox' script detected - syntax error in new script - skipping automatic restart - syntax error is: $res");
        }
        $NextCodeChangeCheck = time + 60;
        $codeChanged = '';
        $wasrun = 1;
    } elsif (time > $NextCodeChangeCheck) {
        while (my ($k,$v) = each %ModuleWatch) {
            if (-e $v->{file} && $v->{filetime} != (my $new = ftime($v->{file}))) {
                $new = timestring($new);
                my $old= timestring($v->{filetime});
                mlog(0,"info: changed module '$k' - '$v->{file}' detected - old: $old - new: $new");
                $ConfigChanged = 1;
                $wasrun = 1;
            }
        }
        $NextCodeChangeCheck = time + 60;
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);

    if ($AutoUpdateSPAMBOX && ! $doShutdown && ! $allIdle && time >= $NextSPAMBOXFileDownload) {
        if (! $noModuleAutoUpdate && ftime("$base/notes/avail_perl_modules.txt") < time - 3600 * 12) {
            if ($AutoUpdateSPAMBOX == 2) {
                mlog(0,"search and install updates for Perl modules");
                %AvailPerlModules = Perl_upgrade_do('--install');
            } else {
                mlog(0,"search updates for Perl modules");
                %AvailPerlModules = Perl_upgrade_do();
            }

            open(my $F , '>' , "$base/notes/avail_perl_modules.txt");
            binmode $F;
            print $F "Available and not installed upgrades of Perl modules at ".&timestring()."\n\n";
            print $F "module\tversion\n\n";
            foreach (sort keys %AvailPerlModules) {
                print $F "$_\t".$AvailPerlModules{$_}."\n";
            }
            my $ucmd = ">perl -MCPAN -e 'CPAN::Shell->install(CPAN::Shell->r)'";
            $ucmd = ">ppm update --install  or  " . $ucmd if ($^O eq 'MSWin32');
            if (scalar keys %AvailPerlModules) {
                print $F "\n\n";
                print $F "To update the modules in this list, stop all perl processes (also spambox!), start a commandline and type $ucmd\n";
                mlog(0,"warning: some Perl modules are not installed and need manual action $ucmd");
            } else {
                print $F "All installed Perl modules are uptodate.\n";
                mlog(0,"info: all installed Perl modules are uptodate.");
            }
            close $F;

            mlog(0,"finished Perl modules updates");
            $wasrun++;
        }
        $wasrun += &downloadSPAMBOXVersion();
        if ($AutoRestartAfterCodeChange && $codeChanged == 2  &&
            ($AsAService || $AsADaemon || $AutoRestartCmd))
        {
            if ($isRunTask) {
                mlog(0,"info: spambox has updated still loaded modules - schedule automatic restart for SPAMBOX after still running task are finished");
                $doShutdown = -1;
            } else {
                mlog(0,"info: spambox has updated still loaded modules - initialize automatic restart for SPAMBOX in 15 seconds");
                $doShutdown = time + 15;
            }
        }
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);

    if($UpdateWhitelist && time >= $saveWhite) {
        ScheduleMapSet('UpdateWhitelist');
        d('ThreadMaintMain - saveWhite');
        if  (!$mysqlSlaveMode || $whitelistdb!~/DB:/o || $failedTable{Whitelist}) {
            &SaveWhitelistOnly();
            $wasrun = 1;
        }
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);
    if($CleanDelayDBInterval && time >= $nextCleanDelayDB) {
        ScheduleMapSet('CleanDelayDBInterval');
        d('ThreadMaintMain - CleanDelayDB');
        if (!$mysqlSlaveMode || $delaydb!~/DB:/o) {
            &CleanDelayDB;
            $wasrun = 1;
        }
    }
    return if(! $ComWorker{$Iam}->{run}|| $wasrun);
    if($CleanPBInterval && time >= $nextCleanPB ) {
        ScheduleMapSet('CleanPBInterval');
        d('ThreadMaintMain - CleanPB');
        if (!$mysqlSlaveMode || $pbdb!~/DB:/o) {
            &CleanPB;
            $wasrun = 1;
        }
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);
    if(time >= $nextCleanIPDom ) {
        $nextCleanIPDom = time + 300;
        d('ThreadMaintMain - CleanIP');
        &cleanCacheIPNumTries();
        &cleanCacheSMTPdomainIP();
        &cleanCacheSSLfailed();
        &cleanCacheLocalFrequency();
        &cleanCacheSubjectFrequency();
        &cleanCacheAUTHErrors();
        &cleanCacheDelayIPPB();
        &cleanCacheEmergencyBlock();
        &cleanCacheRFC822();
        &DMARCgenReport(0) if $ValidateSPF && $DoDKIM && $DMARCReportFrom;
        &ThreadYield();
        $wasrun = 1;
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);
    if($CleanCacheEvery && time >= $nextCleanCache ) {
        ScheduleMapSet('CleanCacheEvery');
        d('ThreadMaintMain - CleanCache');
        if (!$mysqlSlaveMode || $pbdb!~/DB:/o) {
            &CleanCache;
            $wasrun = 1;
        }
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);
    if($remindBATVTag && time >= $nextCleanBATVTag ) {
        d('ThreadMaintMain - cleanCacheBATVTag');
        $nextCleanBATVTag = time + 3600;
        if (!$mysqlSlaveMode || $pbdb!~/DB:/o) {
            &cleanCacheBATVTag;
            $wasrun = 1;
        }
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);
    if($exportInterval && time >= $nextExport) {
        d('ThreadMaintMain - exportExtreme');
        ScheduleMapSet('exportInterval');
        &exportExtreme;
        $wasrun = 1;
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);
    if(   $backupDBInterval
       && time >= $nextDBBackup
       && ! $RunTaskNow{ExportMysqlDB}
       && ! $RunTaskNow{ImportMysqlDB}
       && ! $RunTaskNow{RunRebuildNow}
       )
    {
        ScheduleMapSet('backupDBInterval');
        d('ThreadMaintMain - ExportMysqlDB - backup');
        $RunTaskNow{ExportMysqlDB}=10000;
        $ExportIsRunning = 1;
        &exportMysqlDB('backup');
        $ExportIsRunning = 0;
        $RunTaskNow{ExportMysqlDB}='';
        $wasrun = 1;
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);
    if($SaveStatsEvery && time >= $NextSaveStats) {
        SaveStats();
        $wasrun = 1;
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);
    if( $totalizeSpamStats && time >= $nextStatsUpload) {
        uploadStats();
        $wasrun = 1;
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);
    if(! $noGriplistDownload && ! $noGriplistUpload && $griplist && time >= $NextGriplistDownload) {
        $wasrun = &downloadGrip();
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);
    if($droplist && time >= $NextDroplistDownload) {
        $wasrun = &downloadDropList();
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);
    if($ValidateURIBL && time >= $NextTLDlistDownload) {
        $wasrun = &downloadTLDList();
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);
    if($localBackDNSFile && $DoBackSctr && $downloadBackDNSFile && time >= $NextBackDNSFileDownload) {
        $wasrun = &downloadBackDNS();
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);
    if(($DoGlobalBlack || $GPBDownloadLists || $GPBautoLibUpdate) && time >= $nextGlobalUploadBlack && $CanUseHTTPCompression && $globalClientName && $globalClientPass) {
        $wasrun = &uploadGlobalPB('pbdb.black.db');
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);
    if(($DoGlobalWhite || $GPBDownloadLists || $GPBautoLibUpdate) && time >= $nextGlobalUploadWhite && $CanUseHTTPCompression && $globalClientName && $globalClientPass) {
        $wasrun = &uploadGlobalPB('pbdb.white.db');
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);
    if(! $AutoUpdateSPAMBOX && time >= $NextVersionFileDownload) {
        $wasrun = &downloadVersionFile();
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);

    if ($Groups && $GroupsReloadEvery && time >= $NextGroupsReload && scalar keys %GroupRE && $GroupsDynamic) {
        ScheduleMapSet('GroupsReloadEvery');
        my $fil;
        $fil = $1 if $Groups  =~/^ *file: *(.+)/io;
        if ($fil) {
            $fil="$base/$fil" if $fil!~/^\Q$base\E/io;
            utime(undef,undef,$fil);
            $nextOptionCheck = 0;
        }
    }

    if($ReloadOptionFiles && ! $ConfigChanged && time >= $nextOptionCheck ){
         d('ReloadOptionFiles');
         ScheduleMapSet('ReloadOptionFiles','nextOptionCheck');
         for my $idx (0...$#PossibleOptionFiles) {
          my $f = $PossibleOptionFiles[$idx];
          if($f->[0] ne 'spamboxCfg' || ($f->[0] eq 'spamboxCfg' && $AutoReloadCfg)) {
              if ($Config{$f->[0]}=~/^ *file: *(.+)/io && fileUpdated($1,$f->[0])) {
                my $fl = $1;
                if ($f->[0] eq 'spamboxCfg' && $spamboxCFGTime > $FileUpdate{"$base/spambox.cfgspamboxCfg"}) {
                    $FileUpdate{"$base/spambox.cfgspamboxCfg"} = $spamboxCFGTime;
                    next;
                }
                $ConfigChanged = $f->[0] eq 'spamboxCfg' ? 2 : 1;
                d("file $f->[0] - changed");
                $wasrun = 1;
                last;
             }
          }
        }
        my ($file) = $localBackDNSFile =~ /^ *file: *(.+)/io;
        if ($file &&
            $DoBackSctr &&
            $downloadBackDNSFile &&
            fileUpdated($file,'localBackDNSFile')
           )
        {
            mlog(0,"option list file: '$file' changed (localBackDNSFile)");
            &mergeBackDNS($file);
            mlog(0,"option list file: '$file' reloaded (localBackDNSFile) in to BackDNS");
            $wasrun = 1;
        }
        my $mem = $showMEM ? printMem() : 0;
        mlog(0,"info: worker memory$mem") if $mem && $MaintenanceLog > 2;
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);

    if ($ReloadOptionFiles && time >= $nextHashFileCheck) {
        ScheduleMapSet('ReloadOptionFiles','nextHashFileCheck');
        $wasrun = &checkFileHashUpdate();
        $ConfigChanged = 1 if $wasrun && $HMM4ISP;
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);

    if(time >= $nextDNSCheck) {
        d('updateDNS - call1');
        $nextDNSCheck = time + 60;
        $lastDNScheck = time;
        updateDNS( 'DNSServers', $Config{DNSServers}, $Config{DNSServers}, '' );
        unless ($process_external_cmdqueue) {
            $process_external_cmdqueue = -e "$base/cmdqueue";
            mlog(0, "info: external CMD-queue '$base/cmdqueue' registered") if $process_external_cmdqueue;
        }
    }

    if (isSched($MaxFileAgeSchedule) && time >= $nextFileAgeSchedule && ! $RunTaskNow{RunRebuildNow}) {
        ScheduleMapSet('MaxFileAgeSchedule');
        &cleanUpCollection();
        $wasrun = 1;
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);

    if (isSched($MaxLogAgeSchedule) && time >= $nextLogAgeSchedule && ! $RunTaskNow{RunRebuildNow}) {
        ScheduleMapSet('MaxLogAgeSchedule');
        &cleanUpMailLog();
        $wasrun = 1;
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);

    if (isSched($BlockReportSchedule) && time >= $nextBlockReportSchedule) {
        ScheduleMapSet('BlockReportSchedule');
        &BlockReportGen();
        $wasrun = 1;
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);

    if (isSched($QueueSchedule) && time >= $nextQueueSchedule) {
        ScheduleMapSet('QueueSchedule');
        &BlockReportGen('USERQUEUE');
        $wasrun = 1;
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);

    if ( time > $nextdetectHourJob  ) {
        ( $sec, $min, $hour, $mday, $mon, $year ) = localtime(time);
        my $moreThanOneHour = int((time - $nextdetectHourJob)/3600);
        $nextdetectHourJob = int(time / 3600) * 3600 + 3600;
        $nextdetectHourJob += 15 unless ($nextdetectHourJob + TimeZoneDiff()) % (24 * 3600);  # some seconds more at midnight
                                                                                             # because the maillog rolls
        mlog(0,"info: next hourly scheduler will run at " . &timestring($nextdetectHourJob)) if $MaintenanceLog >= 2;
        checkVersionAge();

        do {
            my $runHour = $hour-$moreThanOneHour;
            $runHour = 24 + $runHour if $runHour < 0;
            d("run HourJobs - scheduled - ($runHour)");
            if ($moreThanOneHour) {
                mlog(0,"info: hourly scheduler for $runHour:00 is running at $hour:00");
            } else {
                cleanCacheT10() if $DoT10Stat;
                mlog(0,"info: hourly scheduler running at $hour:00");
            }

            if (! isSched($MaxFileAgeSchedule) ) {
                &cleanUpCollection() if defined $MaxFileAgeSchedule && $runHour == int($MaxFileAgeSchedule);
            }
            
            if (! isSched($MaxLogAgeSchedule) ) {
                &cleanUpMailLog() if defined $MaxLogAgeSchedule && $runHour == int($MaxLogAgeSchedule);
            }

            &BlockReportGen() if ! isSched($BlockReportSchedule) && $runHour == int($BlockReportSchedule);
            &BlockReportGen('USERQUEUE') if ! isSched($QueueSchedule) && $runHour == int($QueueSchedule);

            &CleanWhitelist() if $UpdateWhitelist && $hour % 2;  # clean and save whitelist every 2 hours

        } while  $moreThanOneHour--;
        
        $wasrun = 1;
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);

    if (time >= $nextBDBsync) {
        mlog(0,"warning: Remote Support is still enabled for connections from IP: $RemoteSupportEnabled") if $RemoteSupportEnabled;
        $wasrun = &BDB_sync(5);
        $nextBDBsync = time + 900;
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);

    if (   ! $doShutdown
        && isSched($MemoryUsageCheckSchedule)
        && time >= $nextMemoryUsageCheckSchedule)
    {
        $Config{MemoryUsageLimit} = $MemoryUsageLimit = (($Config{NumComWorkers} + 3) * 100) if ($Config{MemoryUsageLimit} && $Config{MemoryUsageLimit} < (($Config{NumComWorkers} + 3) * 100));
        if (! $isRunTask) {
            my $usage = int(&memoryUsage() / 1048576);
            if (   $usage
                && ($AsAService || $AsADaemon || $AutoRestartCmd)
                && $MemoryUsageLimit
                && $usage > $MemoryUsageLimit)
            {
                mlog(0,"warning: the memory usage of the current process is $usage MB, which exceeds $MemoryUsageLimit MB (MemoryUsageLimit) - requesting automatic restart for SPAMBOX in 15 seconds");
                $doShutdown = time + 15;
                $wasrun = 1;
            } elsif ($usage && $MaintenanceLog > 2) {
                mlog(0,"info: the memory usage of the current process is $usage MB, limit is ".($MemoryUsageLimit || 'n/a')." MB (MemoryUsageLimit)");
            }
        } elsif ($MaintenanceLog > 2 && (my $usage = int(&memoryUsage() / 1048576))) {
            my $tasks;
            foreach (keys %RunTaskNow) {
                 $tasks .= "$_($RunTaskNow{$_}) " if $RunTaskNow{$_};
                 threads->yield();
            }
            $tasks = " - current running tasks are: $tasks" if $tasks;
            $tasks .= '- the requested restart is delayed until all running tasks are finshed, or skipped if the memory usage will be reduced' if $tasks && $MemoryUsageLimit && $usage > $MemoryUsageLimit;
            mlog(0,"info: the memory usage of the current process is $usage MB, limit is ".($MemoryUsageLimit || 'n/a')." MB (MemoryUsageLimit)$tasks");
        }
        ScheduleMapSet('MemoryUsageCheckSchedule');
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);

    if ($nextBlockRepForwQueue <= time) {
        if (my @q = keys(%BlockRepForwQueue)) {
            mlog(0,'info: checking failed BlockReport forward queue, having '.scalar(@q).' entries') if $ReportLog || $MaintenanceLog;
            my $q;
            while (@q) {
                $q = shift @q;
                if (! $q || ! $BlockRepForwQueue{"$q"}->{'BlockRepForwReTry'}) {
                    delete $BlockRepForwQueue{"$q"};
                    next;
                }
                if ($BlockRepForwQueue{"$q"}->{'BlockRepForwReTry'} > 288) {  # one day every 5 minutes
                    my @h = %{$BlockRepForwQueue{"$q"}->{'BlockRepForwHosts'}};
                    mlog( 0,"error: giving up to forward blocked mail request from $BlockRepForwQueue{$q}->{mailfrom} to host ( @h ) after 24 hours - $@");
                    delete $BlockRepForwQueue{"$q"};
                    next;
                }
                if ($BlockRepForwQueue{"$q"}->{'BlockRepForwNext'} >= time) {
                    $nextBlockRepForwQueue = $BlockRepForwQueue{"$q"}->{'BlockRepForwNext'} if $nextBlockRepForwQueue > $BlockRepForwQueue{"$q"}->{'BlockRepForwNext'};
                    next;
                }
                $Con{"$q"} = {};
                $Con{"$q"}->{$_} = $BlockRepForwQueue{"$q"}->{$_} for ('mailfrom','ip','cip','rcpt','header');
                my %seen;
                while (my ($k,$v) = each(%{$BlockRepForwQueue{"$q"}->{'BlockRepForwHosts'}})) {
                    if (! $k) {
                        delete $BlockRepForwQueue{"$q"}->{'BlockRepForwHosts'}->{$k};
                        next;
                    }
                    next if $v && $seen{$v};
                    BlockReportForwardRequest($q,($v?$v:$k));
                    $wasrun = 1;
                    $seen{$v} = 1 if $v;
                }
                delete $Con{"$q"};
                delete $BlockRepForwQueue{"$q"} unless scalar keys(%{$BlockRepForwQueue{"$q"}->{'BlockRepForwHosts'}});
            }
            $nextBlockRepForwQueue = time + 300 if ($nextBlockRepForwQueue <= time);
        } else {
            $nextBlockRepForwQueue = time + 300;
        }
        if (scalar keys(%BlockRepForwQueue)) {
            eval{Storable::store(\%BlockRepForwQueue, "$base/BlockRepForwQueue.store");};
        } else {
            unlink("$base/BlockRepForwQueue.store");
        }
    }
    return if(! $ComWorker{$Iam}->{run} || $wasrun);

    d('idle loop (5 s)') ;
    my $maxsleep = Time::HiRes::time() + 5;
    while (Time::HiRes::time() < $maxsleep && $ComWorker{$Iam}->{run} && ! $ConfigChanged && ! $ComWorker{$Iam}->{rereadconfig}) {
        if (! ($wasrun = &ThreadMaintMain2($Iam))) {
            &ThreadYield();
            Time::HiRes::sleep(0.3);
            $ThreadIdleTime{$Iam} += 0.3;
        }
    }
    d('MonitorMainThread');
    threads->yield();
    my $ms = $MainLoopLastStep;
    threads->yield();
    my $mst = $MainLoopStepTime;
    threads->yield();
    my $mt = time - $mst;
    if ($mst && $mt > 60 && $MonitorMainThread && $ComWorker{main}) {
      my $text = "error: MainThread stuck for $mt seconds after: $ms - last debug step was: $lastd{0}!";
      my $text2 = "\n";
      my $t = timestring();
      for (1...$NumComWorkers) {
          threads->yield();
          my $tdiff = time - $WorkerLastAct{$_};
          threads->yield();
          $text2 .= "\n$t Worker($_): last loop start before $tdiff seconds - signals: can:$ComWorker{$_}->{CANSIG}, state:$ComWorker{$_}->{SIGSTATE}, never:$ComWorker{$_}->{NEVERSIG} - last debug step is : $lastd{$_}";
      }
      my $tdiff = time - $WorkerLastAct{10001};
      $text2 .= "\n$t Worker(10001): last loop start before $tdiff seconds - last debug step is : $lastd{10001}";
      if ($mst > $MainLoopStepTime2) {
          $MainLoopStepTime2 = $mst;
          my $textI = "$t $text";
          open my $MLS , '>>',"$base/MainThread_stuck_err.log";
          binmode $MLS;
          print $MLS "$textI$text2\n\n\n";
          close $MLS;
          $text2 = s/\n/\r\n/gos;
          if ($canNotify && $Notify && $EmailFrom) {
              &sendNotification(
                $EmailFrom,
                $Notify,
                "SPAMBOX error notification from $myName",
                "logged error on host $myName:\r\n\r\n$textI$text2");
                $t = '*x*';
          } else {
              $t = '';
          }
          mlog(0,"$t$text");
      }
    } elsif ($MainLoopStepTime2) {
        mlog(0,"*x*info: MainThread has retured to normal state after stuck");
        if ($canNotify && $Notify && $EmailFrom) {
            &sendNotification(
              $EmailFrom,
              $Notify,
              "SPAMBOX information notification from $myName",
              "information on host $myName:\r\n\r\nMainThread has retured to normal state after stuck\r\n");
        }
        $MainLoopStepTime2 = 0;
    }
}
