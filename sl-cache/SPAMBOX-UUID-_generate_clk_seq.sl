#line 1 "sub SPAMBOX::UUID::_generate_clk_seq"
package SPAMBOX::UUID; sub _generate_clk_seq {
    my $self = shift;
    my @data;
    push @data, ''  . $$;
    push @data, ':' . Time::HiRes::time();
    return (unpack 'n', _digest_as_octets(2, @data)) & 0x3fff;
}
