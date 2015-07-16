#line 1 "sub main::tosyslog"
package main; sub tosyslog {
  my ($priority, $m) = @_;
  return 0 unless ($priority =~ /info|err|debug/o);
  return 1 if $syslogNextTry && time < $syslogNextTry;
  my $isNix;

  eval{
   if ($sysLogPort && $sysLogIp) {
       $SysLogObj ||= SPAMBOX::Syslog->new(Facility=>$SysLogFac,Priority=>'Debug',SyslogPort=>$sysLogPort,SyslogHost=>$sysLogIp);
       while (@$m) {
           my $msg = shift @$m;
           $msg =~ s/^\s+//o;
           my $ok;
           eval{$ok = $SysLogObj->send($msg,Priority=>$priority);};
           if (! $ok || $@) {
               undef $SysLogObj;
               $syslogNextTry = time + 60;
               @$m = ();
               die "warning: unable to contact or to write to the syslog server $sysLogIp:$sysLogPort\n";
           } else {
               $syslogNextTry = 0;
           }
       }
   } elsif ($CanUseSyslog) {
       $isNix = 1;
       setlogsock('unix');
       openlog('spambox', 'pid,cons', 'mail');
       while (@$m) {
           my $msg = shift @$m;
           $msg =~ s/^\s+//o;
           syslog($priority, $msg);
       }
       closelog();
   }
  };
  if ($@) {
      my $e = $@;
      eval {closelog();} if $isNix;
      $syslogNextTry = time + 60;
      undef $SysLogObj;
      print "warning: syslog error - $e";
      return 0;
  } else {
      $syslogNextTry = 0;
  }
  @$m = ();
  return 1;
}
