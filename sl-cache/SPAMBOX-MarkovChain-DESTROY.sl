#line 1 "sub SPAMBOX::MarkovChain::DESTROY"
package SPAMBOX::MarkovChain; sub DESTROY {
    my $self = shift;
    return until $self;
    $self->store();
    undef $self;
    return;
}
