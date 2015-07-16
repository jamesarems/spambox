#line 1 "sub SPAMBOX::Senderbase::Query::get_whois_results"
package SPAMBOX::Senderbase::Query; sub get_whois_results {
    my $self = shift;
    $self->{ip} = $self->{Address};
    return SPAMBOX::Whois::IP::whoisip_query($self->{ip},$self->{Timeout},undef,undef);
}
