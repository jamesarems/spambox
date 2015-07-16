#line 1 "sub orderedtie::DESTROY"
package orderedtie; sub DESTROY {
    my $self = shift;
    return unless $self;
    eval{$self->flush();};
}
