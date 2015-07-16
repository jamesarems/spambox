#line 1 "sub SPAMBOX::Senderbase::Query::get_cidr"
package SPAMBOX::Senderbase::Query; sub get_cidr {
    my $res = shift;
    my %cidr;
    my @list = ('cidr','netrange','inetnum','inetrev','route','route6','inet6num');
    for (@list) {
        my $entry = $res->{$_};
        $entry =~ s/\s|\r|\n//go;
        next unless $entry;
        &main::mlog(0,"info: whois-cidr: $_: <$entry>") if $main::DebugSPF || $main::SenderBaseLog >= 2;
        if ($entry =~ /\/(\d+)/o) {   # is a CIDR
            &main::mlog(0,"info: whois-cidr: $1") if $main::DebugSPF || $main::SenderBaseLog >= 2;
            $cidr{$1} = 1;
            next;
        }
        if ($main::CanUseCIDRlite && $entry =~ /($main::IPRe)-($main::IPRe)/o) {   # is an IP range
            &main::mlog(0,"info: whois-cidr: $1-$2") if $main::DebugSPF;
            require Net::CIDR::Lite;
            my $range = &main::ipv6expand($1).'-'.&main::ipv6expand($2);
            my $cidr = Net::CIDR::Lite->new;
            eval{$cidr->add_any($range);};
            if ($@) {
                &main::mlog(0,"warning: whois-cidr: failed range to cidr: $1-$2 - $@") if $main::DebugSPF || $main::SenderBaseLog >= 2;
                next;
            }
            my @cidr_list = $cidr->list;
            &main::mlog(0,"info: whois-cidr: $1-$2 => @cidr_list") if $main::DebugSPF || $main::SenderBaseLog >= 2;
            map {$cidr{$1} = 1 if (/\/(\d+)/o)} @cidr_list;
            next;
        }
    }
    return unless scalar keys %cidr;
    &main::mlog(0,'info: whois-cidr: cidr-list: /'.join(' , /',keys %cidr)) if $main::DebugSPF || $main::SenderBaseLog >= 2;
    return &main::max(keys %cidr);
}
