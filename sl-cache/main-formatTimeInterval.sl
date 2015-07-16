#line 1 "sub main::formatTimeInterval"
package main; sub formatTimeInterval {
  my $interval=shift;
  my $res;
  $res.=$_.'d ' if local $_=int($interval/(24*3600)); $interval%=(24*3600);
  $res.=$_.'h ' if $_=int($interval/3600); $interval%=3600;
  $res.=$_.'m ' if $_=int($interval/60); $interval%=60;
  $res.=$interval.'s ' if ($interval || !defined $res);
  $res=~s/\s$//o;
  return $res;
}
