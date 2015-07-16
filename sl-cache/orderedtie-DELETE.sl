#line 1 "sub orderedtie::DELETE"
package orderedtie; sub DELETE {my ($this, $key)=@_;
 $this->{cache}{$key}=$this->{updated}{$key}=undef;
}
