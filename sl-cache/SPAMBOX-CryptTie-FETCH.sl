#line 1 "sub SPAMBOX::CryptTie::FETCH"
package SPAMBOX::CryptTie; sub FETCH { my ($self, $key)=@_;
    my $val = ${$self->{hash}}{$self->{enc}->ENCRYPT($key)};
    return $self->{dec}->DECRYPT($val) if $val;
    return;
}
