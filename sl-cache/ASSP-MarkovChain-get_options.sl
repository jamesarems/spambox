#line 1 "sub ASSP::MarkovChain::get_options"
package ASSP::MarkovChain; sub get_options {
    my $self = shift;
    my ($sequence) = @_;
    my %res;
    %res = map {
        $_ => $self->{chains}{$sequence}{$_} / $self->{totals}{$sequence}
    } keys %{ $self->{chains}{$sequence} };
    return %res;
}
