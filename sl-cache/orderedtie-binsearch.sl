#line 1 "sub orderedtie::binsearch"
package orderedtie; sub binsearch {
 my ($f,$k,$this)=@_;
 return unless $this->{bin};
 my $F;
 (open($F,'<',"$f")) || do {&main::mlog(0,"error: orderedtie is unable to open < $f - $!") if -e $f ;return;};
 binmode($F);
 my $count=0;
 my $siz=my $h=-s $f;
 $siz-=1024;
 my $l=0;
 my $k0=$k;
 $k=~s/([\[\]\(\)\*\^\!\|\+\.\\\/\?\`\$\@\{\}])/\\$1/go; # make sure there's no re chars unqutoed in the key
 while (1) {
  my $m=(($l+$h)>>1)-1024;
  $m=0 if $m < 0;
  seek($F,$m,0);
  my $d; my $read= read($F,$d,2048);
  if( $d=~/\n$k\002([^\n]*)\n/) {
   close $F;
   return $1;
  }
  my ($pre,$first,$fval,$last,$lval,$post)=$d=~/^([^\n]*)\n([^\002]*)\002[^\n]*\n([^\002]*)\002[^\n]*\n([^\002\n]*)$/so;
  last unless defined $first;
  if($k0 gt $first && $k0 lt $last) {
   last;
  }
  if($k0 lt $first) {
   last if $m ==0;
   $h=$m-1024+length($pre);
   $h=0 if $h < 0;
  }
  if($k0 gt $last) {
   last if $m >= $siz;
   $l=$m+$read-length($post);
  }
  if($count++ > 100) {
   &main::mlog(0,"Warning: $f must be repaired ($k0)");
   last;
  }
 }
 close $F;
 return;
}
