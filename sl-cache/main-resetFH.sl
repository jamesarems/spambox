#line 1 "sub main::resetFH"
package main; sub resetFH {
   my $fh = shift;
   my $th = $ThreadHandler{$fh};
   my ($sockIP,$sockPort) = ($fh->sockhost,$fh->sockport);
   my $con = "$sockIP:$sockPort";
   delete $failedFH{$fh};
   if ($sockPort < 1024 && $switchedUser) {
       mlog(0,"error: got at least 10 accept errors at listener $con - assp is unable to renew the listener, because we are not running as root - assp will skip processing this listener for 130 seconds from now");
       unpoll($fh,$writable);
       unpoll($fh,$readable);
       $repollFH{$fh} = time + 10;
       return;
   }
   delete $ThreadHandler{$fh};
   mlog(0,"info: try to renewed listening on port $con - after too many errors");

   if (&matchFH($fh, @lsnRelayI)) {    # renew Relay listener
      foreach my $lsn (@lsnRelay ) {
         delete $SocketCalls{$lsn};
         delete $Con{$lsn} if (exists $Con{$lsn});
         delete $Fileno{fileno $lsn} if (exists $Fileno{fileno $lsn});
         unpoll($lsn,$writable);
         unpoll($lsn,$readable);
         eval{close($lsn) if (fileno($lsn));};
         if ($@) {
             mlog(0,"error: unable to close Socket $lsn - $@");
         }
      }
      &ThreadWaitFinCon;
      my ($lsnRelay,$lsnRelayI)=newListen($relayPort,\&ConToThread,1);
      @lsnRelay = @$lsnRelay; @lsnRelayI = @$lsnRelayI;
      for (@$lsnRelayI) {s/:::/\[::\]:/o;}
      if (@lsnRelay) {
          mlog(0,"info: renewed listening for SMTP relay connections on port @$lsnRelayI - after too many errors");
      } else {
          mlog(0,"error: renewing listening for SMTP relay connections on port @$lsnRelayI - after too many errors");
          &downASSP("try restarting ASSP: failed to renew listener on @$lsnRelayI");
          _assp_try_restart;
      }
      return;
   }

   if (&matchFH($fh, @lsn2I)) {     # renew listener 2
      foreach my $lsn (@lsn2 ) {
         delete $SocketCalls{$lsn};
         delete $Con{$lsn} if (exists $Con{$lsn});
         delete $Fileno{fileno $lsn} if (exists $Fileno{fileno $lsn});
         unpoll($lsn,$writable);
         unpoll($lsn,$readable);
         eval{close($lsn) if (fileno($lsn));};
         if ($@) {
             mlog(0,"error: unable to close Socket $lsn - $@");
         }
      }
      &ThreadWaitFinCon;
      my ($lsn2,$lsn2I) = newListen($listenPort2,\&ConToThread,1);
      @lsn2 = @$lsn2; @lsn2I = @$lsn2I;
      for (@$lsn2I) {s/:::/\[::\]:/o;}
      if (@lsn2) {
          mlog(0,"info: renewed listening for additional SMTP connections on port @$lsn2I - after too many errors");
      } else {
          mlog(0,"error: renewing listening for additional SMTP connections on port @$lsn2I - after too many errors");
          &downASSP("try restarting ASSP: failed to renew listener on @$lsn2I");
          _assp_try_restart;
      }
      return;
   }

   if (&matchFH($fh, @lsnSSLI)) {     # renew listener SSL
      foreach my $lsn (@lsnSSL ) {
         delete $SocketCalls{$lsn};
         delete $Con{$lsn} if (exists $Con{$lsn});
         delete $Fileno{fileno $lsn} if (exists $Fileno{fileno $lsn});
         unpoll($lsn,$writable);
         unpoll($lsn,$readable);
         eval{close($lsn) if (fileno($lsn));};
         if ($@) {
             mlog(0,"error: unable to close Socket $lsn - $@");
         }
      }
      &ThreadWaitFinCon;
      my ($lsnSSL,$lsnSSLI) = newListenSSL($listenPortSSL,\&ConToThread,1);
      @lsnSSL = @$lsnSSL; @lsnSSLI = @$lsnSSLI;
      for (@$lsnSSLI) {s/:::/\[::\]:/o;}
      if (@lsnSSL) {
          mlog(0,"info: renewed listening for secure SMTP connections on port @$lsnSSLI - after too many errors");
      } else {
          mlog(0,"error: renewing listening for secure SMTP connections on port @$lsnSSLI - after too many errors");
          &downASSP("try restarting ASSP: failed to renew listener on @$lsnSSLI");
          _assp_try_restart;
      }
      return;
   }

   if ($th == 2) {      # renew Proxy listener
      &ThreadWaitFinCon;
      while ((my $k,my $v) = each(%Proxy)) {
          if ( $ProxySocket{$k} eq $fh) {
              delete $SocketCalls{$fh};
              delete $Con{$fh} if (exists $Con{$fh});
              delete $Fileno{fileno $fh} if (exists $Fileno{fileno $fh});
              delete $ProxySocket{$k};
              unpoll($fh,$writable);
              unpoll($fh,$readable);
              eval{close($fh);};
              if ($@) {
                  mlog(0,"error: unable to close Socket $fh - $@");
              }

              my ($to,$allow) = split(/<=/o, $v);
              $allow = " allowed for $allow" if ($allow);
              my ($ProxySocket,$dummy) = newListen($k,\&ConToThread,2);
              $ProxySocket{$k} = shift @$ProxySocket;
              for (@$dummy) {s/:::/\[::\]:/o;}
              if ($ProxySocket{$k}) {
                  mlog(0,"info: proxy new started: listening on port @$dummy forwarded to $to$allow - after too many errors");
              } else {
                  mlog(0,"error: renewing proxy on port @$dummy forwarded to $to$allow - after too many errors");
                  &downASSP("try restarting ASSP: failed to renew proxy on port @$dummy forwarded to $to$allow");
                  _assp_try_restart;
              }
              last;
          }
      }
      return;
   }

   delete $SocketCalls{$fh};
   delete $Con{$fh} if (exists $Con{$fh});
   delete $Fileno{fileno $fh} if (exists $Fileno{fileno $fh});
   unpoll($fh,$writable);
   unpoll($fh,$readable);
   eval{close($fh);};
   if ($@) {
       mlog(0,"error: unable to close Socket $fh - $@");
   }
   foreach my $lsn (@lsn ) {          # renew mail listeners
      delete $SocketCalls{$lsn};
      delete $Con{$lsn} if (exists $Con{$lsn});
      delete $Fileno{fileno $lsn} if (exists $Fileno{fileno $lsn});
      unpoll($lsn,$writable);
      unpoll($lsn,$readable);
      eval{close($lsn) if (fileno($lsn));};
      if ($@) {
          mlog(0,"error: unable to close Socket $lsn - $@");
      }
   }
   &ThreadWaitFinCon;
   my ($lsn,$lsnI) = newListen($listenPort,\&ConToThread,1);
   @lsn = @$lsn; @lsnI = @$lsnI;
   for (@$lsnI) {s/:::/\[::\]:/o;}
   if (@lsn) {
       mlog(0,"info: renewed listening for SMTP connections on port @$lsnI - after too many errors");
   } else {
       mlog(0,"error: renewing listening for SMTP connections on port @$lsnI - after too many errors");
       &downASSP("try restarting ASSP: failed to renew listener on @$lsnI");
       _assp_try_restart;
   }
}
