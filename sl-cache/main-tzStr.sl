#line 1 "sub main::tzStr"
package main; sub tzStr {
# calculate the time difference in minutes
my $minoffset = TimeZoneDiff() / 60;

# translate it to "hour-format", so that 90 will be 130, and -90 will be -130
  my $sign=$minoffset<0?-1:+1;
  $minoffset = abs($minoffset)+0.5;
  my $tzoffset = 0;
  $tzoffset = $sign * (int($minoffset/60)*100 + ($minoffset%60)) if $minoffset;
# apply final formatting, including +/- sign and 4 digits
  return sprintf("%+05d", $tzoffset);
}
