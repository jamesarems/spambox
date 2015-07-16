#line 1 "sub main::NewWebConnection"
package main; sub NewWebConnection {
  my $WebSocket = shift;
  my $s;
  d('NewWebConnection');
  &ThreadMonitorMainLoop('MainLoop NewWebConnection');
  if ($WebSocket && "$WebSocket" =~ /SSL/io && $SSLDEBUG > 1) {
      while(my($k,$v)=each(%{${*$WebSocket}{'_SSL_arguments'}})) {
          print "ssl-listener: $k = $v\n";
      }
  }
  eval{$s=$WebSocket->accept;};
  if ($s && "$s" =~ /SSL/io && $SSLDEBUG > 1) {
      while(my($k,$v)=each(%{${*$s}{'_SSL_arguments'}})) {
          print "ssl-accepted: $k = $v\n";
      }
  }
  return unless $s;
  my $ip=$s->peerhost();
  my $port=$s->peerport();
  if($allowAdminConnectionsFrom && ! matchIP($ip,'allowAdminConnectionsFrom',0,0)) {
    mlog(0,"admin connection from $ip:$port rejected by 'allowAdminConnectionsFrom'");
    $Stats{admConnDenied}++;
    close($s);
    return;
  }
# logging is done later (in webRequest()) due to /shutdown_frame page, which auto-refreshes
  &dopoll($s,$readable,POLLIN);
  $SocketCalls{$s}=\&WebTraffic;
  $WebConH{$s} = $s;
}
