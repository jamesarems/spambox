#line 1 "sub ASSP::CryptTie::flush"
package ASSP::CryptTie; sub flush {my ($self)=@_;
    $self->{hashobj}->flush() if $self->{doflush};
}
