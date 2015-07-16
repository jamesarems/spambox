#line 1 "sub main::MainLoop2"
package main; sub MainLoop2 {
  &mlogWrite();
#  &ThreadMonitorMainLoop('MainLoop2 start');
  return if $isRunMainLoop2;
  $isRunMainLoop2 = 1;
  my $hourend = time % 1800;
  mlog(0,'') if (( time - $lastMlog ) > 110 || $hourend < 15);
  mlog(0,'***assp&is%alive$$$') if ((time - $lastmlogWrite) > 120);
  my @canread;
  my $wait;
  my $time=Time::HiRes::time();
  if ($time >= $nextLoop2) {
    if ($SNMPagent) {
        my $res = $SNMPagent->agent_check_and_process(0);
        my $gotRequest = $res;
        while ($res) {
           $lastSNMPrequest = time;
           $res = $SNMPagent->agent_check_and_process(0);
        }
        if (time - $lastSNMPrequest < 15) {
            $MainThreadLoopWait = $gotRequest ? 0 : 0.25;
        }
    }
    serviceCheck() unless $ServiceStopping; # for win32 services
#    &ThreadMonitorMainLoop('MainLoop2 service check');
    do {
      my $stime=Time::HiRes::time(); # poll-loop cycle start time
      if ($IOEngineRun == 0) {
           my $re;
           if ($readable->handles()) {
               $re = $readable->poll($MainThreadLoopWait + $MinPollTimeT/1000);   # wait at least two milliseconds
               @canread = $readable->handles(POLLIN|POLLHUP) if $re > 0;
               if ($re < 0) {
                   &pollerror($readable);
               }
           }
      } else {
         my $wait = int($MainThreadLoopWait + $MinPollTimeT/1000);
         $wait = 1 unless $wait;
         @canread = $readable->can_read( $wait );
      }

      my $itime=Time::HiRes::time(); # loop cycle idle end time
#      &ThreadMonitorMainLoop('MainLoop polled Sockets');
      my $ptime = $itime - $stime;
      $ThreadIdleTime{$WorkerNumber} += $ptime;
      mlog(0,"warning: poll cycle (2) has taken $ptime seconds - this is very much is too long")
          if ($ConnectionLog >= 2 and $ptime > 3);

#      &ThreadMonitorMainLoop('MainLoop2 poll Sockets');
      while (@canread) {
        my $fh = shift @canread;
        if ($fh && ($SocketCalls{$fh}==\&WebTraffic || $SocketCalls{$fh}==\&NewWebConnection || $SocketCalls{$fh}==\&NewStatConnection || $SocketCalls{$fh}==\&StatTraffic)) {
          next if exists $MainLoopInWebFH{$fh};
          $MainLoopInWebFH{$fh} = 1;
          $SocketCalls{$fh}->($fh) if (! exists $ConDelete{$fh});
          delete $MainLoopInWebFH{$fh};
        }
      }
#      &ThreadMonitorMainLoop('MainLoop2 read from socket');

      $time=Time::HiRes::time();
    } until (@canread==0 || $time >= $nextLoop2);
    $nextLoop2=Time::HiRes::time()+0.3; # 0.3s for other tasks

    if($RestartEvery && $itime >= $endtime) {
# time to quit -- after endtime and we're bored.
        &downASSP("restarting");
        _assp_try_restart;
    }

    if ($doShutdown > 0 && $itime >= $doShutdown) {
      &downASSP("restarting");
      _assp_try_restart;
    }
  }
  $isRunMainLoop2 = 0;
}
