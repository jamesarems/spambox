#line 1 "sub SPAMBOX::Senderbase::Query::new"
package SPAMBOX::Senderbase::Query; sub new {
    my $class = shift;
    my %attrs = @_;
    my $sep = ',';
    &DESTROY();
    &main::d('SPAMBOX::Senderbase::Query::new -> '.$attrs{Address} );

    $attrs{Address} || die "No 'Address' attribute in call to SPAMBOX::Senderbase::Query::new()\n";
    if ($attrs{Address} !~ /^$main::IPRe$/o) {
        # assume it is a hostname instead of an IP
        my $addr = $attrs{Address};
        eval {$attrs{Address} = inet_ntoa(scalar(gethostbyname($addr)||pack("N", 0)));} ||
        ($main::CanUseIOSocketINET6 && eval(<<EOT));
              require Socket6;
              $attrs{Address} = Socket6::inet_ntop( AF_INET6, scalar( Socket6::gethostbyname2($addr,AF_INET6) ) );
EOT
    }
    $attrs{Address} || die "No valid 'Address' attribute in call to SPAMBOX::Senderbase::Query::new()\n";
    $attrs{Timeout} ||= $TIMEOUT;
    $attrs{Host} ||= init($sep);
    $attrs{main} ||= 'main';
    $attrs{sep}  ||= $sep;

    my $self = bless { %attrs }, $class;

    return $self if ($self->{useWhoIs});

    my $reversed_ip = ($attrs{Address}=~/^$main::IPv4Re/o)
                            ? join('.', reverse(split(/\./o,$attrs{Address})))
                            : &main::ipv6hexrev($attrs{Address},36);
    die("IPv6 addresses are not supported\n") unless $reversed_ip;
    my $mask = $attrs{Mask} ? ".$attrs{Mask}" : '';
    my @query;
    my %seen;
    @{$self->{query}} = ();
    for my $host ($lastSuccessHost, split(/\s*$sep\s*/o,$attrs{Host})) {
        next unless $host;
        next if $seen{$host};
        $seen{$host} = 1;
        &main::d("SenderBase-Query: $reversed_ip$mask.$host , TXT");
        my $res = &main::queryDNS("$reversed_ip$mask.$host", "TXT");
        if (! $res) {
            $lastSuccessHost = '';
            next;
        }
        push @{$self->{query}}, grep { $_->type eq 'TXT'} $res->answer;
        next if $main::lastDNSerror eq 'TIMEOUT';
        if ($main::lastDNSerror ne 'NXDOMAIN') {
            $lastSuccessHost = $host;
            last;
        } else {
            $lastSuccessHost = '';
        }
    }
    $lastSuccessHost = '' if $main::lastDNSerror eq 'TIMEOUT' || ! @{$self->{query}};
    return $self;
}
