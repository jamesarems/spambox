#line 1 "sub RBL::txt_hash"
package RBL; sub txt_hash {
    my $self = shift;
    if (wantarray) { %{ $self->{ txt } } }
    else { $self->{ txt } }
}
