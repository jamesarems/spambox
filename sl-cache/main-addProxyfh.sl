#line 1 "sub main::addProxyfh"
package main; sub addProxyfh {
  my ($fh,$friend) =@_;
  $SocketCalls{$fh}=\&ProxyTraffic;
  $SocketCalls{$friend}=\&ProxyTraffic;
  $fh->blocking(0);
  $friend->blocking(0);
  &dopoll($fh,$readable,POLLIN);
  &dopoll($friend,$readable,POLLIN);
  binmode($fh);
  binmode($friend);
  $Con{$fh} = {};
  $Con{$friend} = {};
  $Con{$fh}->{friend}   = $friend;
  $Con{$fh}->{isProxyCon} = 1;
  $Con{$fh}->{timelast} = time;
  $Con{$friend}->{friend}   = $fh;
  $Con{$friend}->{isProxyCon} = 1;
  $Con{$friend}->{timelast} = $Con{$fh}->{timelast};
}
