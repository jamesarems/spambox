#line 1 "sub main::WebDone"
package main; sub WebDone {
  my $fh=shift;
  $fh = $WebConH{$fh} if exists $WebConH{$fh};
  $fh = $StatConH{$fh} if exists $StatConH{$fh};
  unpoll($fh,$readable);
  unpoll($fh,$writable);
  d("closing web connection $fh");
  if (! exists $ConDelete{$fh}) {
     $ConDelete{$fh} = \&WebDone;
     return;
  }
  delete $SocketCalls{$fh};
  delete $WebCon{$fh};
  delete $StatCon{$fh};
  delete $WebConH{$fh};
  delete $StatConH{$fh};
  delete $Con{$fh};
  eval{close($fh);};
}
