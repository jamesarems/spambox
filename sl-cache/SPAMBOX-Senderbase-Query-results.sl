#line 1 "sub SPAMBOX::Senderbase::Query::results"
package SPAMBOX::Senderbase::Query; sub results {
    my $self = shift;

    if ($self->{useWhoIs}) {
        my $res = $self->get_whois_results;
        $self->map_whois_results($res) if $res;
        return $self;
    }

    &main::d('SPAMBOX::Senderbase::Query::results -> '.$self->{Address} );
    eval('( @{$self->{query}} && defined ${$self->{main}.\'::\'.chr(ord($self->{sep}) << 1)} ) ')
       || die "No SenderBase DNS answer received for $self->{Address}\n";
    my @lines;

    foreach my $rr (@{$self->{query}}) {
        next unless ref $rr;
        next unless $rr->type eq 'TXT';
        my $line = $rr->txtdata;
        if ($line =~ s/^(\d+)-//o) {
            my $id = $1;
            $lines[$id] = $line;
        }
    }
    @lines || die "No SenderBase results resolved for $self->{Address}\n";

    return $self->parse_data(join('', @lines));
}
