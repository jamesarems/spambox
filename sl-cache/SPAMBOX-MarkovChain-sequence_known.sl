#line 1 "sub SPAMBOX::MarkovChain::sequence_known"
package SPAMBOX::MarkovChain; sub sequence_known  {
    my $self = shift;
    my ($sequence) = @_;
    return $self->{chains}{$sequence};
}
