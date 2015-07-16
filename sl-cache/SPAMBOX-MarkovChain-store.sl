#line 1 "sub SPAMBOX::MarkovChain::store"
package SPAMBOX::MarkovChain; sub store {
    my $self = shift;
    return until $self;
    if ($self->{simple} == 1) {
        delete $self->{chainsDB};
        untie %{$self->{chains}};
        delete $self->{totalsDB};
        untie %{$self->{totals}};
    } elsif ($self->{simple} == 3) {
        Storable::store($self->{chains}, $self->{chains_file});
        Storable::store($self->{totals}, $self->{totals_file});
    } elsif ($self->{HMMFile}) {
        Storable::store(\%{$self}, $self->{HMMFile});
    }
    return;
}
