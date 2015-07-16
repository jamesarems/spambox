#line 1 "sub ASSP::MarkovChain::get_totals"
package ASSP::MarkovChain; sub get_totals {
    my $self = shift;
    my ($sequence) = @_;
    return $self->{totals}{$sequence};
}
