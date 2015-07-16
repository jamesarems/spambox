#line 1 "sub ASSP::CryptTie::DELETE"
package ASSP::CryptTie; sub DELETE {my ($self, $key)=@_;
    delete ${$self->{hash}}{$self->{enc}->ENCRYPT($key)};
}
