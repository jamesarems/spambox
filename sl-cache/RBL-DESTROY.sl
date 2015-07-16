#line 1 "sub RBL::DESTROY"
package RBL; sub DESTROY {
    my $self = shift;
    return until $self;
    undef $self;
}
