#line 1 "sub ASSP::MarkovChain::get_value"
package ASSP::MarkovChain; sub get_value {
    my $self = shift;
    my ($sequence,$symbol) = @_;
    return $self->{chains}{$sequence}{$symbol};
}
