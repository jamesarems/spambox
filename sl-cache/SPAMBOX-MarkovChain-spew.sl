#line 1 "sub SPAMBOX::MarkovChain::spew"
package SPAMBOX::MarkovChain; sub spew {
    my $self = shift;
    my %args = @_;
    return if $self->{simple};

    local $; = $self->{seperator};

    my $longest_sequence = $self->longest_sequence()
      or return;

    my $length   = $args{length} || 30;
    my $subchain = $args{longest_subchain} || $length;

    my @fin; # final chain
    my @sub; # current sub-chain
    if ($args{complete} && ref $args{complete} eq 'ARRAY') {
        @sub = @{ $args{complete} };
    }

    while (@fin < $length) {
        if (@sub && (!$self->sequence_known($sub[-1]) || (@sub > $subchain))) { # we've gone terminal
            push @fin, @sub;
            @sub = ();
            next if $args{force_length}; # ignore stop_at_terminal
            last if $args{stop_at_terminal};
        }

        unless (@sub) {
            if ($args{strict_start}) {
                my @starts = @{ $self->{_start_states} };
                @sub = $starts[rand $#starts];
            }
            else {
                @sub = split $;, $self->random_sequence();
            }
        }

        my $consider = 1;
        if (@sub > 1) {
            $consider = int rand ($longest_sequence - 1);
        }

        my $start = join($;, @sub[-$consider..-1]);

        next unless $self->sequence_known($start); # loop if we missed

        my $cprob;
        my $target = rand;

        my %options = $self->get_options($start);
        for my $word (keys %options) {
            $cprob += $options{$word};
            if ($cprob >= $target) {
                push @sub, $word;
                last;
            }
        }
    }

    $#fin = $length
      if $args{force_length};

    @fin = map { $self->{_symbols}{$_} } @fin
      if $self->{_recover_symbols};

    return @fin;
}
