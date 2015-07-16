#line 1 "sub SPAMBOX::CryptTie::flush"
package SPAMBOX::CryptTie; sub flush {my ($self)=@_;
    $self->{hashobj}->flush() if $self->{doflush};
}
