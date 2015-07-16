#line 1 "sub orderedtie::CLEAR"
package orderedtie; sub CLEAR {my ($this)=@_;
 my $F;
 open($F,'>',"$this->{fn}"); binmode($F); print $F "\n"; close $F;
 $this->{cache}={};
 $this->{updated}={};
 $this->{cnt}=0;
}
