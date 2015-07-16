#line 1 "sub main::queryDNS"
package main; sub queryDNS {
	my ($domain, $type) = @_;
    my @query;
    $lastDNSerror = undef;
    if (ref($domain)) {
        @query = @$domain;
    } else {
        push @query, $domain, $type;
    }
    if (! $DNSReuseSocket || $DNSresolverTimeS{$WorkerNumber} < time ) {
        DNSSocketsClose(values(%sDNSSockets));
        %sDNSSockets = ();
        mlog(0,"info: DNSresolverTimeS timed out") if $DebugSPF && $DNSReuseSocket;
        d("info: DNSresolverTimeS timed out",1);
    } else {
        DNSSocketsCleanup(values(%sDNSSockets));
    }
    my @nameservers = getNameserver();
    if ("@nameservers" =~ /^\s*$/o ) {
        $lastDNSerror = 'NO_NAME_SERVER_GIVEN';
        mlog(0,"info: NO_NAME_SERVER_GIVEN - closing existing DNS sockets") if $DebugSPF;
        DNSSocketsClose(values(%sDNSSockets));
        %sDNSSockets = ();
        $DNSresolverTimeS{$WorkerNumber} = 0;
        return;
    }
    my @isready;
    my $retry = int($DNSretrans / (@nameservers || 1)) * $DNSretry;
    my %rslv;
    my %sockets;
    my $sel;
    my $packet;
    my %failed;
    my $error;
    my @packet_header_ids;
    while (1) {
        $sel = IO::Select->new();
      QNAMESERVER:
        for (0..$#nameservers) {
            my @q = @query;
            my $ns = $nameservers[$_] or next;
            $rslv{$ns} = eval { getDNSResolverSingle( unpack("A1",${chr(ord("\026") << 2)})-2, nameservers => [$ns], getLocalAddress('DNS',$ns) ) };
            if ($rslv{$ns}) {
                while (@q) {
                    my $s;
                    my ($domain, $type) = (shift(@q), shift(@q));
                    my $packet = eval{$rslv{$ns}->make_query_packet($domain, $type);};
                    next if(! $packet);
                    my $packet_data = $packet->data;
                    my $headerid = $packet->header->id;
                    next if(! $packet_data || ! defined($headerid));
                    if ($s = $sDNSSockets{$ns}) {
                        mlog(0,"info: reuse DNS socket for $ns - ".join(' ', map {$_->string} $packet->question)) if $DebugSPF;
                        d("reuse DNS socket for $ns",1);
                        my $dst_sockaddr;
                        my ($addr,$port) = $ns =~ /^\[?($IPRe)\]?(?::($PortRe))?$/io;
                        $port ||= 53;
                        if (! $rslv{$ns}->force_v4() && $CanUseIOSocketINET6) {
                            my $old_wflag = $^W;
                            $^W = 0;
                            no strict 'subs';   ## no critic
                            $dst_sockaddr = [ Socket6::getaddrinfo($addr, $port, AF_UNSPEC, SOCK_DGRAM, 0, AI_NUMERICHOST) ]->[3];
                            $^W = $old_wflag ;
                        } else {
                            $dst_sockaddr = sockaddr_in($port, inet_aton($addr));
                        }
                        if (! $dst_sockaddr) {
                            delete $sDNSSockets{$ns};
                            mlog(0,"warning: can't get numeric address for $ns");
                        } else {
                            if (! $s->send($packet_data,0,$dst_sockaddr)) {
                               mlog(0,"info: new DNS socket for $ns after send failed") if $DebugSPF;
                               d("new DNS socket for $ns after send failed",1);
                               $sDNSSockets{$ns} = $s = eval { $rslv{$ns}->bgsend($packet); };
                            }
                        }
                    } else {
                        $sDNSSockets{$ns} = $s = eval { $rslv{$ns}->bgsend($packet); };
                        mlog(0,"info: new DNS socket for $ns") if $DebugSPF;
                        d("new DNS socket for $ns",1);
                    }
                    if ($s) {
                        $rslv{$ns}->errorstring('');
                        push @packet_header_ids, $headerid;
                        eval{$s->blocking(0);};
                        $sel->add($s) unless $sockets{$s};
                        $sockets{$s} = $ns;
                        mlog(0,"info: sent DNS query for '$domain' type '$type' to nameserver $ns ID $headerid") if $ConnectionLog > 2 || $DebugSPF;
                    } else {
                        $nextDNSCheck = $lastDNScheck + 5;
                        next QNAMESERVER;
                    }  # if s
                } # while q
            } # if rslv
        } # qnameserver
        $retry--;
        if ( ! scalar keys %sockets ) {
            if ($retry >= 0) {
                undef $sel;
                %rslv = ();
                next;
            }
            undef $sel;
            %rslv = ();
            DNSSocketsClose(values(%sDNSSockets));
            %sDNSSockets = ();
            $DNSresolverTimeS{$WorkerNumber} = 0;
            mlog(0,"error: DNS - unable to create any UDP socket to nameservers (@nameservers) - $@");
            $lastDNSerror = 'SOCKETERROR';
            $nextDNSCheck = $lastDNScheck + 5;
            return;
        }
        my $st = Time::HiRes::time();
        @isready = $sel->can_read($DNStimeout);
        my $qt = Time::HiRes::time() - $st;
        $ThreadIdleTime{$WorkerNumber} += $qt;
        if ($DebugSPF) {
            my $a_ns;
            for (@isready) {$a_ns .= ' '.$sockets{$_};}
            mlog(0,sprintf("info: DNS query time %.3f -%s",$qt,$a_ns));
        }
        $DNSmaxQueryTime = max($DNSmaxQueryTime,$qt);
        $DNSminQueryTime = min($DNSminQueryTime,$qt);
        $DNSsumQueryTime += $qt;
        $DNSQueryCount++;

        if (! @isready && $retry < 0) {
            mlog(0,"warning: DNS - DNS query timeout ($DNStimeout sec - retry $DNSretry) for '$domain' type '$type'") if $ConnectionLog > 1 || $DebugSPF;
            undef $sel;
            foreach (keys %sockets) { eval{$_->close;}; }
            %sockets = ();
            %rslv = ();
            DNSSocketsClose(values(%sDNSSockets));
            %sDNSSockets = ();
            $DNSresolverTimeS{$WorkerNumber} = 0;
            $lastDNSerror = 'TIMEOUT';
            return;
        } elsif (! @isready) {
            mlog(0,"warning: DNS - DNS query timeout ($DNStimeout sec - for '$domain' type '$type'") if $ConnectionLog > 1 || $DebugSPF;
            undef $sel;
            foreach (keys %sockets) { eval{$_->close;}; }
            %sockets = ();
            %rslv = ();
            DNSSocketsClose(values(%sDNSSockets));
            %sDNSSockets = ();
            $DNSresolverTimeS{$WorkerNumber} = 0;
            @packet_header_ids = ();
            next;
        }

        %failed = ();
        my $gotAnswer;
        my $tout = 0.0;
        while (@isready || (@isready = $sel->can_read($tout)) ) {
            my $sock = shift @isready;
            undef $packet;
            if (($packet = eval { $rslv{$sockets{$sock}}->bgread($sock); }) && $packet->answer) {
                mlog(0,"info: got DNS DATA answer from nameserver $sockets{$sock}") if $ConnectionLog > 2 || $DebugSPF;
                if (! $packet->header->qr()) {
                    mlog(0,"info: ignoring invalid DNS DATA answer from nameserver $sockets{$sock}") if $ConnectionLog > 2 || $DebugSPF;
                    $tout = $DNStimeout - (Time::HiRes::time() - $st);
                    $tout = 0.0 if $tout < 0;
                    undef $packet;
                    next;
                }
                if ($DebugSPF) {
                    for ($packet->question) {
                        mlog(0,"DNS-question was: ".$_->string);
                    }
                    for ($packet->answer) {
                        mlog(0,"DNS-answer is: ".$_->string);
                    }
                }
                $lastDNSerror = $error = undef;
                delete $failed{$sockets{$sock}};
                my $headerid = $packet->header->id;
                unless (grep {$_ == $headerid} @packet_header_ids) {
                    mlog(0,"info: ignoring outdated DNS DATA answer from nameserver $sockets{$sock} ID $headerid (expected ID's: @packet_header_ids)") if $ConnectionLog > 2 || $DebugSPF;
                    $tout = $DNStimeout - (Time::HiRes::time() - $st);
                    $tout = 0.0 if $tout < 0;
                    undef $packet;
                    next;
                }
                mlog(0,"info: got valid DNS DATA answer from nameserver $sockets{$sock} ID $headerid") if $ConnectionLog > 2 || $DebugSPF;
                $gotAnswer = 1;
                last;
            }
            if ($@) {
                $error = $@;
                $rslv{$sockets{$sock}}->errorstring($error);
                mlog(0,"error: DNS - can't read from nameserver $sockets{$sock} - $error - $!");
                $sel->remove($sock);
                $lastDNSerror = $failed{$sockets{$sock}} = 'SOCKET-READ-ERROR - '.$error;
                $tout = $DNStimeout - (Time::HiRes::time() - $st);
                $tout = 0.0 if $tout < 0;
                undef $packet;
                next;
            }
            my $headerid;
            if ($packet) {
                if (! $packet->header->qr()) {
                    mlog(0,"info: ignoring invalid NON-DATA answer from nameserver $sockets{$sock}") if $ConnectionLog > 2 || $DebugSPF;
                    $tout = $DNStimeout - (Time::HiRes::time() - $st);
                    $tout = 0.0 if $tout < 0;
                    undef $packet;
                    next;
                }
                $headerid = $packet->header->id;
                my $rcode = $packet->header->rcode;
                unless (grep {$_ == $headerid} @packet_header_ids) {
                    mlog(0,"info: ignoring outdated NON-DATA answer '$rcode' from nameserver $sockets{$sock} ID $headerid (expected ID's: @packet_header_ids)") if $ConnectionLog > 2 || $DebugSPF;
                    $tout = $DNStimeout - (Time::HiRes::time() - $st);
                    $tout = 0.0 if $tout < 0;
                    undef $packet;
                    next;
                }
                $rslv{$sockets{$sock}}->errorstring($rcode);
            }
            if ($rslv{$sockets{$sock}}->errorstring =~ /^(NXDOMAIN|NOERROR)$/o) {
                $lastDNSerror = $1;
                mlog(0,"info: got valid DNS NON-DATA answer '$1' from nameserver $sockets{$sock} ID $headerid") if $ConnectionLog > 1 || $DebugSPF;
                $gotAnswer = 1;
                %failed = ();
                last;
            }
            $lastDNSerror = $rslv{$sockets{$sock}}->errorstring;
            undef $packet;
            $tout = $DNStimeout - (Time::HiRes::time() - $st);
            $tout = 0.0 if $tout < 0;
        }
        last if $retry < 0 || $gotAnswer;
        $error = undef;
        %rslv = ();
        next;
    } # while 1
    if (! $DNSReuseSocket || (! $packet && keys(%failed))) {
        foreach (keys %sockets) { eval{$_->close;}; }
        mlog(0,"info: destroy old single DNSresolver") if $DebugSPF;
        d("destroy old single DNSresolver",1);
        DNSSocketsClose(values(%sDNSSockets));
        %sDNSSockets = ();
        $DNSresolverTimeS{$WorkerNumber} = 0;
    } else {
        $DNSresolverTimeS{$WorkerNumber} = time + $DNSresolverLifeTime;
    }
    %sockets = ();
    %rslv = ();
    return $packet;
}
