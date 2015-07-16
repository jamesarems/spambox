#line 1 "sub ASSP::MarkovChain::longest_sequence"
package ASSP::MarkovChain; sub longest_sequence {
    my $self = shift;
    return $self->{longest_sequence} if exists $self->{longest_sequence};

    local $; = $self->{seperator};

    my $l = 0;
    for (keys %{ $self->{chains} }) {
        my @tmp = split $;, $_;
        my $length = scalar @tmp;
        $l = $length if $length > $l;
    }
    $self->{longest_sequence} = $l;
    return $l;
}
