#line 1 "sub main::doneProxy"
package main; sub doneProxy {
  my $fh = shift;
  $fh = $Con{$fh}->{self} if $Con{$fh}->{self};
  my $cliIP;
  my $serIP;
  if (! exists $ConDelete{$fh}) {
     $ConDelete{$fh} = \&doneProxy;
     return;
  }
  return unless $fh;
  return unless $Con{$fh};
  my $mode ="Proxy";
  $mode = "TLS" if ($Con{$fh}->{runTLS});
  eval{$cliIP=$fh->peerhost().":".$fh->peerport();
  $serIP=$Con{$fh}->{friend}->peerhost().":".$Con{$fh}->{friend}->peerport();};
  mlog(0,"info: closed $mode connection for $serIP and $cliIP") if $ConnectionLog;
  if ($Con{$fh}->{friend}) {
    delete $SocketCalls{$Con{$fh}->{friend}};
    unpoll($Con{$fh}->{friend},$readable);
    unpoll($Con{$fh}->{friend},$writable);
    if ($mode eq "TLS") {
      if (exists $SMTPSession{$Con{$fh}->{friend}}) {
        delete $SMTPSession{$Con{$fh}->{friend}};
        threads->yield;
        $smtpConcurrentSessions=0 if --$smtpConcurrentSessions < 0;
        threads->yield;
        $SMTPSessionIP{Total}-- ;
        threads->yield;
        delete $SMTPSessionIP{$Con{$Con{$fh}->{friend}}->{ip}} if (--$SMTPSessionIP{$Con{$Con{$fh}->{friend}}->{ip}} <= 0);
        threads->yield;
      }
  }
  eval{close($Con{$fh}->{friend});} if (fileno($Con{$fh}->{friend}));
  threadConDone($Con{$fh}->{friend});
  delete $Con{$Con{$fh}->{friend}};
  }
  delete $SocketCalls{$fh};
  unpoll($fh,$readable);
  unpoll($fh,$writable);
  if ($mode eq "TLS") {
    if (exists $SMTPSession{$fh}) {
      delete $SMTPSession{$fh};
      threads->yield;
      $smtpConcurrentSessions=0 if --$smtpConcurrentSessions<0;
      threads->yield;
      $SMTPSessionIP{Total}--;
      threads->yield;
      delete $SMTPSessionIP{$Con{$fh}->{ip}} if (--$SMTPSessionIP{$Con{$fh}->{ip}} <= 0);
      threads->yield;
    }
  }
  threadConDone($fh);
  eval{close($fh);}  if (fileno($fh));
  delete $Con{$fh};
}
