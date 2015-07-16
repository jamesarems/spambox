#line 1 "sub orderedtie::STORE"
package orderedtie; sub STORE {
 my ($this, $key, $value)=@_;
 $this->{cache}{$key}=$this->{updated}{$key}=$value;
}
