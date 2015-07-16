#line 1 "sub orderedtie::FIRSTKEY"
package orderedtie; sub FIRSTKEY { my $this=shift;
 if ($this->{bin}) {
     $this->flush();
     $this->{ptr}=1;
 } else {
     @{$this->{keys}} = keys(%{$this->{cache}});
 }
 $this->NEXTKEY();
}
