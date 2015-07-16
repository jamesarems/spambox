#line 1 "sub SPAMBOX::Senderbase::Query::parse_data"
package SPAMBOX::Senderbase::Query; sub parse_data {
    my $self = shift;
    $self->{ip} = $self->{Address};
    $self->{raw_data} = shift;

    foreach my $part (split(/\|/o, $self->{raw_data})) {
        my ($key, $value) = split(/=/o, $part, 2);
        if (exists($keys{$key})) {
            $self->{$keys{$key}} = $value;
        }
        else {
            &main::mlog(0,"info: SenderBase found unknown Key and Value: '$key'=>'$value' in DNS answer for '$self->{ip}' - please inform the developement");
            $self->{"key_$key"} = $value;
        }
    }
    $self->{how} = 'Senderbase';
    return $self;
}
