#line 1 "sub Net::SMTP::DESTROY_SSLNS"
package Net::SMTP; sub DESTROY_SSLNS {
    my $me = shift;
    return unless $me;
    my $clean = ${*$me}{'net_smtp_clns'};
    unless ($clean) {
        undef $me;
        return;
    }
    my @sslisa;
    for (@IO::Socket::SSL::ISA) {
        push @sslisa, $_ if $_ ne 'Net::SMTP';
    }
    @IO::Socket::SSL::ISA = @sslisa;
    if (ref($clean) eq 'CODE') {
        *IO::Socket::SSL::DESTROY = $clean;
        $clean->($me);
    }
    undef $me;
}
