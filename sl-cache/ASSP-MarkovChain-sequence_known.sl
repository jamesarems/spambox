#line 1 "sub ASSP::MarkovChain::sequence_known"
package ASSP::MarkovChain; sub sequence_known  {
    my $self = shift;
    my ($sequence) = @_;
    return $self->{chains}{$sequence};
}
