#line 1 "sub orderedtie::resetCache"
package orderedtie; sub resetCache {
 my $this=shift;
 $this->{cnt}=0;
 $this->{age} = &main::ftime($this->{fn});
 $this->{cache}={%{$this->{updated}}};
}
