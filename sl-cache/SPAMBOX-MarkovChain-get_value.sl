#line 1 "sub SPAMBOX::MarkovChain::get_value"
package SPAMBOX::MarkovChain; sub get_value {
    my $self = shift;
    my ($sequence,$symbol) = @_;
    return $self->{chains}{$sequence}{$symbol};
}
