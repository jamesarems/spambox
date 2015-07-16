#line 1 "sub orderedtie::FETCH"
package orderedtie; sub FETCH { my ($this, $key)=@_;
 return $this->{cache}{$key} if exists $this->{cache}{$key};
 $this->resetCache() if($this->{cnt}++ > $this->{max} || ($this->{cnt} & 0x1f) == 0 && &main::ftime($this->{fn}) != $this->{age});

 return $this->{cache}{$key}=binsearch($this->{fn},$key,$this);
}
