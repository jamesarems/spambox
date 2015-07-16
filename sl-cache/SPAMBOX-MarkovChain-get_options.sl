#line 1 "sub SPAMBOX::MarkovChain::get_options"
package SPAMBOX::MarkovChain; sub get_options {
    my $self = shift;
    my ($sequence) = @_;
    my %res;
    %res = map {
        $_ => $self->{chains}{$sequence}{$_} / $self->{totals}{$sequence}
    } keys %{ $self->{chains}{$sequence} };
    return %res;
}
