#line 1 "sub ASSP::CryptTie::DESTROY"
package ASSP::CryptTie; sub DESTROY {my $self = shift; return unless $self; undef $self->{hashobj}; untie %{$self->{hash}}; undef $self; }
