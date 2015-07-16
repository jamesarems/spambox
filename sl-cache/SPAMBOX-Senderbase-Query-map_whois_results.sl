#line 1 "sub SPAMBOX::Senderbase::Query::map_whois_results"
package SPAMBOX::Senderbase::Query; sub map_whois_results {
    my ($self, $res) = @_;
    for (sort keys %{$res}) {
        &main::mlog(0,"info: whois result - $_: $res->{$_}") if $main::DebugSPF || $main::SenderBaseLog >= 2;
    }
    $self->{org_name} = $res->{orgname} || $res->{owner} || $res->{'org-name'} || $res->{descr} || $res->{role};
    $self->{hostname_matches_ip} = 'Y';
    $self->{ip_country} = $res->{country};
    $self->{ip_cidr_range} = get_cidr($res);
    $self->{how} = 'WHOIS';
    $self->{hostname} = [&main::PTRCacheFind($self->{ip})]->[2] || &main::getRRData($self->{ip},'PTR');
    &main::mlog(0,"info: whois - CIDR result: $self->{ip}/$self->{ip_cidr_range}") if $main::DebugSPF || $main::SenderBaseLog >= 2;
}
