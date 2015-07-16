#line 1 "sub SPAMBOX::CryptTie::DESTROY"
package SPAMBOX::CryptTie; sub DESTROY {my $self = shift; return unless $self; undef $self->{hashobj}; untie %{$self->{hash}}; undef $self; }
