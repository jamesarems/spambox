#line 1 "sub main::localmail"
package main; sub localmail {
  my $h = shift;
  d("localmail - $h",1);
  return 0 unless $h;
#(my $package, my $file, my $line, my $Subroutine, my $HasArgs, my $WantArray, my $EvalText, my $IsRequire) = caller(0);
#d("localmail - $package, $file, $line, $Subroutine, $HasArgs, $WantArray, $EvalText, $IsRequire");
  $h = $1 if $h=~/\@([^@]*)/o;
  return &localdomains($h);
}
