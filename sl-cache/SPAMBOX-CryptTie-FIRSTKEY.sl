#line 1 "sub SPAMBOX::CryptTie::FIRSTKEY"
package SPAMBOX::CryptTie; sub FIRSTKEY { my $self=shift;
    my $fkey = $self->{hashobj}->FIRSTKEY;
    return unless $fkey;
    return $self->{dec}->DECRYPT($fkey);
}
