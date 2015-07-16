#line 1 "sub ASSP::CryptTie::NEXTKEY"
package ASSP::CryptTie; sub NEXTKEY { my ($self, $lastkey)=@_;
    my $nkey = $self->{hashobj}->NEXTKEY($lastkey);
    return unless $nkey;
    return $self->{dec}->DECRYPT($nkey);
}
