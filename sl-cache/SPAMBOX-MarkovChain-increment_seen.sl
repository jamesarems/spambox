#line 1 "sub SPAMBOX::MarkovChain::increment_seen"
package SPAMBOX::MarkovChain; sub increment_seen {
    my $self = shift;
    my ($sequence, $symbol, $count) = @_;

    $count ||= 1;
    $self->{totals}{$self->{privacy}.$sequence} += $count;
    if ($self->{simple}) {
        $self->{chains}{"$self->{privacy}$sequence$self->{seperator}$symbol"} += $count;
        return;
    } else {
        $self->{chains}{$self->{privacy}.$sequence}{$symbol} += $count;
    }
    return unless $self->{top};
    return if $self->{privacy};
    my $length = () = $sequence =~ /($self->{seperator})/g;
    $length++;
    return if $length < $self->{longest};
    my $top = $self->{top};
    my $j = $top;
    for (0..$top) {
        if ($self->{top10}{$_} eq $sequence){
            delete $self->{top10}{$_};
            delete $self->{top10count}{$_};
            $j = $_;
            last;
        }
    }
    for (0..$j) {
        if ($self->{top10count}{$_} < $self->{totals}{$sequence}) {
           if ($_ < $j) {
               for (my $i = $j; $i > $_; $i--) {
                   $self->{top10}{$i} = $self->{top10}{$i - 1};
                   $self->{top10count}{$i} = $self->{top10count}{$i - 1};
               }
           }
           $self->{top10}{$_} = $sequence;
           $self->{top10count}{$_} = $self->{totals}{$sequence};
           last;
        }
    }
}
