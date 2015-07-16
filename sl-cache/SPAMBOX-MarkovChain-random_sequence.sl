#line 1 "sub SPAMBOX::MarkovChain::random_sequence"
package SPAMBOX::MarkovChain; sub random_sequence {
    my $self = shift;

    my ($k, $v);
    my $i = 0;
    my $r = int rand keys %{ $self->{chains} };
    while (($k,$v) = each %{ $self->{chains} }) {
        last if $i++ == $r;
    }
    return $k;
}
