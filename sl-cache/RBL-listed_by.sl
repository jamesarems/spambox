#line 1 "sub RBL::listed_by"
package RBL; sub listed_by {
    my $self = shift;
    sort keys %{ $self->{ results } };
}
