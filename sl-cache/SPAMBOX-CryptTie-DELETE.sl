#line 1 "sub SPAMBOX::CryptTie::DELETE"
package SPAMBOX::CryptTie; sub DELETE {my ($self, $key)=@_;
    delete ${$self->{hash}}{$self->{enc}->ENCRYPT($key)};
}
