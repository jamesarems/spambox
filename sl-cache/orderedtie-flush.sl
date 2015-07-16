#line 1 "sub orderedtie::flush"
package orderedtie; sub flush {
 my $this=shift;
 return unless %{$this->{updated}};
 my $f=$this->{fn};
 my $O;
 my $I;
 (open($O,'>',"$f.tmp")) || do {&main::mlog(0,"error: orderedtie is unable to open > $f.tmp - $!") if -e $this->{fn} ;return;};
 binmode($O);
 (open($I,'<',"$f")) || print $O "\n";
 binmode($I) if fileno($I);
 local $/="\n";
 my @l=(sort keys %{$this->{updated}});
 my ($k,$d,$r,$v);
 while (fileno($I) && ($r=<$I>)) {
  ($k,$d)=split(/\002/o,$r);
  while (@l && $l[0] lt $k) {
   $v=$this->{updated}{$l[0]};
   print $O "$l[0]\002$v\n" if $v;
   shift(@l);
  }
  if($l[0] eq $k) {
   $v=$this->{updated}{$l[0]};
   print $O "$l[0]\002$v\n" if $v;
   shift(@l);
  } else {
   print $O $r;
  }
 }
 while (@l) {
  $v=$this->{updated}{$l[0]};
  print $O "$l[0]\002$v\n" if $v;
  shift(@l);
 }
 close $I if fileno($I);
 close $O;
 $f =~ s/\\/\//go;
 my $t = time + 20;
 do {
     sleep 1 unless unlink("$f");
 } while (-e $f && time < $t);
 mlog(0,"error: orederedtie is unable to delete file $f - $!") if -e $f;
 rename("$f.tmp", $f) or &main::mlog(0,"error: orderedtie is unable to rename file $f.tmp to $f - $!");
 $this->{updated}={};
}
