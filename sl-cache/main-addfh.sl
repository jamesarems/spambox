#line 1 "sub main::addfh"
package main; sub addfh {
  my ($fh,$getline,$friend) =@_;
  d('addfh');
  $SocketCalls{$fh}=\&SMTPTraffic;
  $fh->blocking(0);
  &dopoll($fh,$readable,POLLIN);
  &dopoll($fh,$writable,POLLOUT);
  binmode($fh);
  $Con{$fh} = {};
  keys %{$Con{$fh}} = 128;
  $Con{$fh}->{getline}  = $getline;
  $Con{$fh}->{friend}   = $friend;
  $Con{$fh}->{timestart}= time;
  $Con{$fh}->{timelast} = $Con{$fh}->{timestart};
  $Con{$fh}->{socketcalls} = 0;
  $Con{$fh}->{fno} = fileno($fh);
}
