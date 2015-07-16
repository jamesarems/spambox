#line 1 "sub main::done"
package main; sub done {
  my $fh=shift;
  return unless $fh;
  d('done');
  done2($Con{$fh}->{friend}) if $Con{$fh}->{friend};
  done2($fh);
}
