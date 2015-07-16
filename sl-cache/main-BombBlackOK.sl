#line 1 "sub main::BombBlackOK"
package main; sub BombBlackOK {
  my ($fh,$bd) = @_;
  return 1 if !$DoBlackRe;
  return BombBlackOK_Run($fh,$bd);
}
