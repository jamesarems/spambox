#line 1 "sub ASSP::CryptTie::EXISTS"
package ASSP::CryptTie; sub EXISTS { my ($self, $key)=@_;
    return exists ${$self->{hash}}{$self->{enc}->ENCRYPT($key)};
}
