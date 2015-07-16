#line 1 "sub main::ProxyTraffic"
package main; sub ProxyTraffic {
  my $fh = shift;
  d('ProxyTraffic');
  $SMTPbuf = '';
  my $friend = $Con{$fh}->{friend};
  $fh->blocking(0) if $fh->blocking;
  &sigoffTry(__LINE__);
  my $hasread = $fh->sysread($SMTPbuf,4096);
  &sigonTry(__LINE__);
  if($hasread > 0 or length($SMTPbuf) > 0) {
    &dopoll($friend,$writable,POLLOUT);
    $Con{$friend}->{outgoing}.=$SMTPbuf;
    $Con{$fh}->{timelast} = time;
    $Con{$friend}->{timelast} = $Con{$fh}->{timelast};
  } else {
    doneProxy($fh) if ($Con{$fh}->{timelast} + 1 < time);
#    doneProxy($fh) if ($Con{$fh}->{type} eq 'C');
  }
  $SMTPbuf = '';
}
