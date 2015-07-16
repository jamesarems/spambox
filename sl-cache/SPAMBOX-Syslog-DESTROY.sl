#line 1 "sub SPAMBOX::Syslog::DESTROY"
package SPAMBOX::Syslog; sub DESTROY {
    my $self = shift;
    eval{$self->{Socket}->close;};
    undef $self;
}
