#line 1 "sub RBL::listed_hash"
package RBL; sub listed_hash {
    my $self = shift;
    %{ $self->{ results } };
}
