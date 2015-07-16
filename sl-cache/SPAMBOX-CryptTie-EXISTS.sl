#line 1 "sub SPAMBOX::CryptTie::EXISTS"
package SPAMBOX::CryptTie; sub EXISTS { my ($self, $key)=@_;
    return exists ${$self->{hash}}{$self->{enc}->ENCRYPT($key)};
}
