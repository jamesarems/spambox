#line 1 "sub ASSP::CryptTie::FIRSTKEY"
package ASSP::CryptTie; sub FIRSTKEY { my $self=shift;
    my $fkey = $self->{hashobj}->FIRSTKEY;
    return unless $fkey;
    return $self->{dec}->DECRYPT($fkey);
}
