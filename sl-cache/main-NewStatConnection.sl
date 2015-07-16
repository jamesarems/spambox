#line 1 "sub main::NewStatConnection"
package main; sub NewStatConnection {
  my $StatSocket = shift;
  my $s;
  &ThreadMonitorMainLoop('MainLoop NewStatConnection');
  d('NewStatConnection');
  $s=$StatSocket->accept;
  return unless $s;
  my $ip=$s->peerhost();
  my $port=$s->peerport();
  if($allowStatConnectionsFrom && ! matchIP($ip,'allowStatConnectionsFrom',0,0)) {
    mlog(0,"stat connection from $ip:$port rejected by allowStatConnectionsFrom");
    $Stats{statConnDenied}++;
    close($s);
    return;
  }
# logging is done later (in webRequest()) due to /shutdown_frame page, which auto-refreshes
  &dopoll($s,$readable,POLLIN);
  $SocketCalls{$s}=\&StatTraffic;
  $StatConH{$s} = $s;
}
