#line 1 "sub SPAMBOX::CryptTie::NEXTKEY"
package SPAMBOX::CryptTie; sub NEXTKEY { my ($self, $lastkey)=@_;
    my $nkey = $self->{hashobj}->NEXTKEY($lastkey);
    return unless $nkey;
    return $self->{dec}->DECRYPT($nkey);
}
