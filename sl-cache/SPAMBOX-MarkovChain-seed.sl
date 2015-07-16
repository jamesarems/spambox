#line 1 "sub SPAMBOX::MarkovChain::seed"
package SPAMBOX::MarkovChain; sub seed {
    my $self = shift;
    my %args = @_;

    my @symbols = @{ $args{symbols} };
    return unless @symbols;

    my $count = $self->{count} || 1;

    local $; = $self->{seperator};

    $self->{privacy} = $args{privacy} ? $args{privacy}.$; : '';
    my $longest = $args{longest} || $self->{longest} || 4;
    $self->{longest} ||= $longest;
    my $shortest = $args{shortest} || $self->{shortest} || 1;
    $self->{shortest} ||= $shortest;

    push @{ $self->{_start_states} }, $symbols[0] unless $self->{nostarts};

    if ($self->{_recover_symbols}) {
        $self->{_symbols}{$_} = $_ for @symbols;
    }

    for my $length ($shortest..$longest) {
        for (my $i = 0; ($i + $length) < @symbols; $i++) {
            my $link = join($;, @symbols[$i..$i + $length - 1]);
            $self->increment_seen($link, $symbols[$i + $length],$count);
        }
    }
    delete $self->{longest_sequence};
    return unless $self->{top};
    for (0..9) {
        if ($self->{top10count}{$_} < 2){
            delete $self->{top10}{$_};
            delete $self->{top10count}{$_};
        }
    }
}
