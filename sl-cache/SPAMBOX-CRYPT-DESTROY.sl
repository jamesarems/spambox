#line 1 "sub SPAMBOX::CRYPT::DESTROY"
package SPAMBOX::CRYPT; sub DESTROY {
    my $self = shift;
    undef $self;
}
