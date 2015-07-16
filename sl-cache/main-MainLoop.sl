#line 1 "sub main::MainLoop"
package main; sub MainLoop {
  my $maxwait = shift;
  my $entrytime = Time::HiRes::time();
  my $hourend = time % 1800;
  mlog(0,'') if (( time - $lastMlog ) > 110 || $hourend < 15);
  mlog(0,'***assp&is%alive$$$') if (! $DisableSyslogKeepAlive && (time - $lastmlogWrite) > 120);
  &ThreadMonitorMainLoop('MainLoop start');
  &ConDone();
  my @canread;
  &getChangedConfigValue() if @changedConfig;
  &tellThreadsReReadConfig() if ($ConfigChanged);
  &mlogWrite();
  if ($maxwait && $syncToDo) {
      my $hassync;
      &ThreadMonitorMainLoop('Doing Config Sync');
      foreach ( sort { &syncSortCFGRec() } Glob("$base/configSync/*.cfg")) {
          next if -d $_;
          &syncConfigReceived($_);
          unlink($_) if -e "$_";
          &syncWriteConfig();
          $hassync = 1;
          last;
      }
      $syncToDo = $hassync;
      &mlogWrite();
  }
  my $stime=Time::HiRes::time(); # loop cycle start time
  if ($maxwait && $ThreadsDoStatus && $stime - $lastThreadsDoStatus > 5) {
      d('stop Status collection');
      $ThreadsDoStatus = 0;
      mlog(0,"info: stop Threads collecting status information") if($MaintenanceLog);
      &ThreadYield();
      %ConFno = ();
      undef %ConFno;
  }
  if ($maxwait && $process_external_cmdqueue && time % 5 == 0 && (open my $cmdq, '<',"$base/cmdqueue")) {
      &ThreadMonitorMainLoop('processing external command queue');
      while (my $line = (<$cmdq>)) {
          next if ($line =~ /^\s*[#;]/o);
          my ($sub,$parm) = parseEval($line);
          next unless $sub;
          mlog(0,"info: executing command '$line' from $base/cmdqueue");
          if ($sub eq 'RunEval' or $sub eq '&RunEval' or $sub eq \&RunEval or $sub eq &RunEval) {
              &RunEval($parm);
          } else {
              $sub =~ s/^\&//o;
              eval{$sub->(split(/\,/o,$parm));};
          }
          mlog(0,"error executing command '$line' from $base/cmdqueue - $@") if $@;
          &mlogWrite();
      }
      close $cmdq;
      unlink "$base/cmdqueue";
  }
  if ($maxwait && $SNMPagent) {
      d('check SNMPagent');
      my $maxSNMPtime = Time::HiRes::time() + 2;  # max two seconds for SNMP request processing
      my $res = $SNMPagent->agent_check_and_process(0);
      my $gotRequest = $res;
      while ( $res && (Time::HiRes::time() < $maxSNMPtime) ) {
         $lastSNMPrequest = time;
         $res = $SNMPagent->agent_check_and_process(0);
      }
      if (time - $lastSNMPrequest < 15) {
          $MainThreadLoopWait = $gotRequest ? 0 : 0.25;
      }
      &mlogWrite() if $gotRequest;
  }
  &ThreadMonitorMainLoop('MainLoop start poll Sockets');
  $stime=Time::HiRes::time(); # poll-loop cycle start time
  if ($IOEngineRun == 0) {
      my $re;
      if ($readable->handles()) {
          $re = $readable->poll( min($MainThreadLoopWait,$maxwait) + $MinPollTimeT/1000);   # wait at least two milliseconds
          @canread = $readable->handles(POLLIN|POLLHUP) if $re > 0;
          if ($re < 0) {
              &pollerror($readable);
          }
      }
  } else {
    my $wait = int( min($MainThreadLoopWait,$maxwait) + $MinPollTimeT/1000);
    $wait = $maxwait unless $wait;
    @canread = $readable->can_read( $wait );
  }
  my $itime = Time::HiRes::time(); # loop cycle idle end time
  $ThreadIdleTime{$WorkerNumber} += $itime - $stime;
  return ($itime - $entrytime) if (! $maxwait && ! @canread);

  &ThreadMonitorMainLoop('MainLoop polled Sockets');
  my $ptime = $itime - $stime;
  mlog(0,"warning: the operating system socket poll cycle has taken $ptime seconds - this is very much is too long")
      if ($ConnectionLog >= 2 and $ptime > 3);
  $nextLoop2=$itime+0.3; # global var
  &mlogWrite();
  &ThreadYield() unless @canread;
  while (@canread) {
    my $fh = shift @canread;
    if ($fh && $SocketCalls{$fh}) {
      if ($SocketCalls{$fh}==\&WebTraffic || $SocketCalls{$fh}==\&NewWebConnection || $SocketCalls{$fh}==\&NewStatConnection || $SocketCalls{$fh}==\&StatTraffic) {
        next if exists $MainLoopInWebFH{$fh};
        $MainLoopInWebFH{$fh} = 1;
        $SocketCalls{$fh}->($fh) if (! exists $ConDelete{$fh});
        delete $MainLoopInWebFH{$fh};
      } else {
        unless ($shuttingDown || $allIdle) {
            mlog(0,"info: $WorkerName got connection request") if ($WorkerLog);
            $SocketCalls{$fh}->($fh);
        }
      }
      &mlogWrite();
    } else {
        next if (! $SocketCalls{$fh} && $errorFH);
        mlog(0,"Warning: $WorkerName found socket without SocketCalls - please report!");
        eval{
          delete $SocketCalls{$fh} if (exists $SocketCalls{$fh});
          delete $Con{$fh} if (exists $Con{$fh});
          delete $WebCon{$fh} if (exists $WebCon{$fh});
          unpoll($fh,$readable);
          unpoll($fh,$writable);
          delete $ConDelete{$fh} if (exists $ConDelete{$fh});
          eval{close($fh)} if (fileno($fh));
        };
        &mlogWrite();
    }
  }
  $errorFH = 0;
  &ThreadMonitorMainLoop('MainLoop read from sockets');
  d('mainloop before servicecheck');
  serviceCheck(); # for win32 services
  &ThreadMonitorMainLoop('MainLoop service check');

  &SMTPSessionLimitCheck();
  &ThreadMonitorMainLoop('MainLoop session limit check');
  &mlogWrite();

# database connection check is done independent from any time values
# the complete check for all tables should never take more than 0.05 seconds if all is ok
  if (($CanUseTieRDBM or $CanUseBerkeleyDB) && $DBisUsed && $itime >= $nextDBcheck) { # check - do we have lost any DB connection
                                  # and reconnect if possible
      my $cdbstime=Time::HiRes::time(); # to get the check time
      my $cdberror=&checkDBCon(int($itime)+$ThreadsWakeUpInterval + 2); # check every 120 seconds   # or switch to files
      my $cdbetime= sprintf("%.3f",(Time::HiRes::time()) - $cdbstime); # to get the check time
      d("info: database connection was checked in $cdbetime seconds");
      mlog(0,"warning: $WorkerName - check the database connections has taken $cdbetime seconds (max=1.000s)") if ($cdbetime>1 && ! $cdberror); #0.1s is ok
      &ThreadMonitorMainLoop('MainLoop database check');
      my $mem = $showMEM ? printMem() : 0;
      mlog(0,"info: worker memory$mem") if $mem && $MaintenanceLog > 2;
  }

  &ThreadYield();

  if ($itime >= $nextThreadsWakeUp) {   # wakeup all threads every some sec
     &ThreadsWakeUp();
     $nextThreadsWakeUp = int($itime)+$ThreadsWakeUpCheck;
     &ThreadMonitorMainLoop('MainLoop wakeup threads');
  }

  d('mainloop before restart check');

  if($RestartEvery && $itime >= $endtime) {
# time to quit -- after endtime and we're bored.
        mlog(0,"info: restart time is reached - waiting until all connection are gone but max 5 minutes");
        while ($smtpConcurrentSessions && time < $endtime + 300) {
            my $tendtime = $endtime;
            $endtime = time + 10000;
            &MainLoop2();
            $endtime = $tendtime;
            Time::HiRes::sleep(0.5);
            $ThreadIdleTime{$WorkerNumber} += 0.5;
        }
        &downASSP("restarting");
        _assp_try_restart;
  }

  &ThreadMonitorMainLoop('Mainloop after restart check');

  if ($doShutdown > 0 && $itime >= $doShutdown) {
    &downASSP("restarting");
    _assp_try_restart;
  }
  &ConDone();

  if ($allIdle > 0 && ! $Config{DisableSMTPNetworking}) {
      configUpdateSMTPNet('DisableSMTPNetworking',$Config{DisableSMTPNetworking},'2','');
      $ConfigChanged = 1;
  } elsif ($allIdle < 0 && $Config{DisableSMTPNetworking}) {
      configUpdateSMTPNet('DisableSMTPNetworking',$Config{DisableSMTPNetworking},'0','');
      $ConfigChanged = 1;
      $allIdle = 0;
  }

  if (time > $nextdetectGhostCon) {
      &detectWebGhostCon();
      &detectGhostCon();
      $nextdetectGhostCon = time + 300;
  }
  foreach my $fh (keys %repollFH) {
      if ($repollFH{$fh} < time) {
          dopoll($fh,$readable,POLLIN);
          dopoll($fh,$writable,POLLOUT);
          delete $repollFH{$fh};
      }
  }
  &mlogWrite();
  undef %Con unless keys(%Con);
  undef %ConDelete unless keys(%ConDelete);
  undef %SocketCalls unless keys(%SocketCalls);
  undef %repollFH unless keys(%repollFH);
  undef %WebConH unless keys(%WebConH);
  undef %MainLoopInWebFH unless keys(%MainLoopInWebFH);
  undef %StatConH unless keys(%StatConH);
  undef %MainLoopInWebFH unless keys(%MainLoopInWebFH);
  return (Time::HiRes::time() - $entrytime);
}
