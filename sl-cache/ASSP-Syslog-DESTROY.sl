#line 1 "sub ASSP::Syslog::DESTROY"
package ASSP::Syslog; sub DESTROY {
    my $self = shift;
    eval{$self->{Socket}->close;};
    undef $self;
}
