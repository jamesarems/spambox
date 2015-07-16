#line 1 "sub SPAMBOX::CryptTie::STORE"
package SPAMBOX::CryptTie; sub STORE { my ($self, $key, $value)=@_;
    ${$self->{hash}}{$self->{enc}->ENCRYPT($key)}=$self->{enc}->ENCRYPT($value);
}
