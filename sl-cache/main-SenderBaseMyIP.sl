#line 1 "sub main::SenderBaseMyIP"
package main; sub SenderBaseMyIP {
    my $ip = shift;
    d('SenderBaseMyIP');
    return $MySenderBaseCode if $MySenderBaseCode;

    return eval {
            my $results;
            my $how = $enableWhois & 1;  # 0 = SB only, 1 = whois only, 2 = SB first, 3 = whois first
            eval {$results = SPAMBOX::Senderbase::Query->new(
                Address   => $ip,
                Timeout   => ($DNStimeout * ($DNSretry + 1)) || 10,
                useWhoIs => $how
              )->results;};
            $how = $enableWhois >> 1;    # 0 = all done, 1 = next SB or whois
            die $@ if ! $how && $@;      # die if error and only one thing to do
            if ($how) {
                $how = $enableWhois == 2 ? 1 : 0;  # do whois or SB
                $results = SPAMBOX::Senderbase::Query->new(
                    Address   => $ip,
                    Timeout   => ($DNStimeout * ($DNSretry + 1)) || 10,
                    useWhoIs => $how
                  )->results if (! (ref($results) && $results->{ip_country}));
            }
    $MySenderBaseCode = $results->{ip_country};
    $MySenderBaseCode;
    };
}
