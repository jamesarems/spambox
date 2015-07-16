#line 1 "sub main::syncSortCFGRec"
package main; sub syncSortCFGRec {
   my ($ga) = $main::a =~ /\Q$base\E\/configSync\/([^\.]+)/o;
   my ($gb) = $main::b =~ /\Q$base\E\/configSync\/([^\.]+)/o;
   if ($ConfigNum{$ga} < $ConfigNum{$gb}) { -1; }
   elsif ($ConfigNum{$ga} == $ConfigNum{$gb}) { 0; }
   else { 1; }
}
