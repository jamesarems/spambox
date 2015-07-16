#line 1 "sub main::niceConfigPos"
package main; sub niceConfigPos {
 my $counterT = -1;
 my $num = 0;
 my $head;
 %ConfigPos = ();
 %ConfigNum = ();
 %glosarIndex = ();
 for my $idx (0...$#ConfigArray) {
   my $c = $ConfigArray[$idx];
   if(@{$c} == 5) {
      $counterT++;
      $num++;
      $head = $c->[4];
      $head =~ s/<a\s+href.*<\/a>//io;
   } else {
      $ConfigPos{$c->[0]} = $counterT;
      $ConfigNum{$c->[0]} = $num++;
      $glosarIndex{$c->[0]} = $head;
   }
 }
}
