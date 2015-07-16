#line 1 "sub main::addsslfh"
package main; sub addsslfh {
  my ($oldfh,$sslfh,$friend) =@_;
  $SocketCalls{$sslfh}=$SocketCalls{$oldfh};
  $sslfh->blocking(0);
  binmode($sslfh);
  %{$Con{$sslfh}} = %{$Con{$oldfh}};
  $Con{$sslfh}->{friend} = $friend;
  $Con{$sslfh}->{self} = $sslfh;
  $Con{$sslfh}->{oldfh} = $oldfh;
  $SMTPSession{$sslfh} = $sslfh;
  delete $SMTPSession{$oldfh};
  if ($Con{$sslfh}->{type} eq 'C') {
    $Con{$sslfh}->{client}   = $sslfh;
    $Con{$sslfh}->{server}   = $friend;
    $Con{$sslfh}->{myheaderCon} .= "X-Assp-Client-TLS: yes\r\n";
    $Stats{smtpConnTLS}++ unless $Con{$sslfh}->{relayok};
  } else {
    $Con{$friend}->{myheaderCon} .= "X-Assp-Server-TLS: yes\r\n";
  }
  &dopoll($sslfh,$readable,POLLIN);
  &dopoll($sslfh,$writable,POLLOUT);
  $Con{$oldfh}->{movedtossl} = 1;
  my $fno = $Con{$oldfh}->{fno} ;
  if (exists $ConFno{$fno}) {delete $ConFno{$fno};}
  delete $Fileno{$fno} if (exists $Fileno{$fno});
  $Con{$sslfh}->{fno} = fileno($sslfh);
  $Fileno{$Con{$sslfh}->{fno}} = $sslfh;
  d("info: switched connection from $oldfh to $sslfh");
}
