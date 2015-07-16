#line 1 "sub ASSP::CryptTie::STORE"
package ASSP::CryptTie; sub STORE { my ($self, $key, $value)=@_;
    ${$self->{hash}}{$self->{enc}->ENCRYPT($key)}=$self->{enc}->ENCRYPT($value);
}
