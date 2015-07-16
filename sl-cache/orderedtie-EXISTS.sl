#line 1 "sub orderedtie::EXISTS"
package orderedtie; sub EXISTS { my ($this, $key)=@_;
 return FETCH($this, $key);
}
