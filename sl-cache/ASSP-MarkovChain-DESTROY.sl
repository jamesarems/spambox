#line 1 "sub ASSP::MarkovChain::DESTROY"
package ASSP::MarkovChain; sub DESTROY {
    my $self = shift;
    return until $self;
    $self->store();
    undef $self;
    return;
}
