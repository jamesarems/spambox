#line 1 "sub orderedtie::TIEHASH"
package orderedtie; sub TIEHASH {
 my ($c,$fn)=@_;
 my $self={
  fn => $fn,
  age => &main::ftime($fn),
  cnt => 0,
  cache => {},
  updated => {},
  ptr => 1,
  bin => 1,  # search in file or do all in memory
  max => $main::OrderedTieHashTableSize
 };
 bless $self, $c;
 if ($main::CanUseAsspSelfLoader && exists $AsspSelfLoader::Cache{'orderedtie::DESTROY'}) {
     &DESTROY();
 }
 if ($main::CanUseAsspSelfLoader && exists $AsspSelfLoader::Cache{'orderedtie::UNTIE'}) {
     &UNTIE(0,0);
 }
 return $self;
}
