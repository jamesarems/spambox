#line 1 "sub main::localvrfy2MTA"
package main; sub localvrfy2MTA {
  my ($fh,$h) = @_;
  return 0 unless $DoVRFY;
  return localvrfy2MTA_Run($fh,$h);
}
