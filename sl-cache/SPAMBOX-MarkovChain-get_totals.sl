#line 1 "sub SPAMBOX::MarkovChain::get_totals"
package SPAMBOX::MarkovChain; sub get_totals {
    my $self = shift;
    my ($sequence) = @_;
    return $self->{totals}{$sequence};
}
