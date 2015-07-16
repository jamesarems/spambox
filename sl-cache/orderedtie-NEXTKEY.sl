#line 1 "sub orderedtie::NEXTKEY"
package orderedtie; sub NEXTKEY { my ($this, $lastkey)=@_;
 if (! $this->{bin}) {
     return shift @{$this->{keys}};
 }
 local $/="\n";
 my $F;
 (open($F,'<',"$this->{fn}")) || do {&main::mlog(0,"error: orderedtie is unable to open < $this->{fn} - $!") if -e $this->{fn} ;return;};
 binmode($F);
 seek($F,$this->{ptr},0);
 my $r=<$F>;
 return unless $r;
 $this->{ptr}=tell $F;
 close $F;
 my ($k,$v)=$r=~/([^\002]*)\002([^\n]*)\n/so;
 if(!exists($this->{cache}{$k}) && $this->{cnt}++ > $this->{max}) {
  $this->{cnt}=0;
  $this->{cache}={%{$this->{updated}}};
 }
 $this->{cache}{$k}=$v;
 $k;
}
