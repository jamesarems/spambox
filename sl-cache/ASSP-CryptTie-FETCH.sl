#line 1 "sub ASSP::CryptTie::FETCH"
package ASSP::CryptTie; sub FETCH { my ($self, $key)=@_;
    my $val = ${$self->{hash}}{$self->{enc}->ENCRYPT($key)};
    return $self->{dec}->DECRYPT($val) if $val;
    return;
}
