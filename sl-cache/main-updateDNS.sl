#line 1 "sub main::updateDNS"
package main; sub updateDNS {
    my ( $name, $old, $new, $init ) = @_;
    return '' if $WorkerNumber != 0 && $WorkerNumber != 10000;
    return '' if $WorkerNumber == 10000 && $ComWorker{$WorkerNumber}->{rereadconfig};
    mlog( 0, "AdminUpdate: $name - DNS configuration updated from '$old' to '$new'" )
      unless $init || $new eq $old || $name eq 'updateDNS';
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    
    if ($CanUseDNS) {
        my (@ns,@ns_def);
        my $domainName;
        my $nnew;
        ($nnew , $domainName) = split(/\s*\=\>\s*/o, $new);
        @ns_def = @ns = split( /\s*\|\s*/o, $nnew );
        @ns = () if $UseLocalDNS;

        $DNSresolverTime{$WorkerNumber} = 0;
        my $res;
        if ($orgNewDNSisSET) {
            $res = $orgNewDNSResolver->(   'Net::DNS::Resolver',
                                           tcp_timeout => $DNStimeout,
                                           udp_timeout => $DNStimeout,
                                           retrans     => $DNSretrans,
                                           retry       => $DNSretry
                                           );
        } else {
            $res = Net::DNS::Resolver->new(   tcp_timeout => $DNStimeout,
                                              udp_timeout => $DNStimeout,
                                              retrans     => $DNSretrans,
                                              retry       => $DNSretry
                                           );
        }
        if ( @ns && ! $UseLocalDNS ) {
            $res->nameservers(@ns);
        }
        if ($UseLocalDNS && ! $res->nameservers && @ns_def) {
            $res->nameservers(@ns_def);
            mlog(0,"error: got NO name servers from the operating system ( UseLocalDNS ) - using '@ns_def' defined in 'DNSServers'");
        }
        my %nservers;
        my $ld = $lastd{$WorkerNumber};
        d('updateDNS: get back name servers before mode setup');
        map { $nservers{$_} = 1; } $res->nameservers;
        $lastd{$WorkerNumber} = $ld;
        my @usedNameServers = keys(%nservers);
        %nservers = ();
        eval('$forceDNSv4=!($CanUseIOSocketINET6 && &matchARRAY(qr/^$IPv6Re$/,\@usedNameServers));');
        getRes('force', $res);
        my @oldnameserver = @nameservers;
        d('updateDNS: get back name servers after mode setup');
        map { $nservers{$_} = 1; } $res->nameservers;
        @usedNameServers = keys(%nservers);
        $lastd{$WorkerNumber} = $ld;
        %nservers = ();
        mlog(0,"error: there is NO DNS-server specified - at least TWO DNS-servers are required!") unless scalar(@usedNameServers);
        mlog(0,"warning: there is only ONE DNS-server specified (@usedNameServers) - at least TWO DNS-servers are required!") if scalar(@usedNameServers) == 1 && (($MaintenanceLog > 1) || $DNSResponseLog);
        
        my @availDNS;
        my @diedDNS;
        $domainName ||= 'sourceforge.net';
        my %DNSResponseTime;
        foreach my $dnsServerIP (@usedNameServers) {
            $res->nameservers($dnsServerIP);
            my $btime = Time::HiRes::time();
            my $response = $res->search($domainName);

            my $atime = int((Time::HiRes::time() - $btime) * 1000);
            mlog( 0, "info: Name Server $dnsServerIP: ResponseTime = $atime ms for $domainName" ) if $DNSResponseLog;
            $DNSResponseTime{$dnsServerIP} = $atime;
	        if ($response) {
                push (@availDNS,$dnsServerIP);
            } else {
                push (@diedDNS,$dnsServerIP);
            }
        }
        @availDNS = sort {$DNSResponseTime{$main::a} <=> $DNSResponseTime{$main::b}} @availDNS;
        my @newDNS = @availDNS;
        push @newDNS , @diedDNS unless scalar @newDNS;
        foreach (@availDNS) {
            mlog( 0, "info: Name Server $_: OK " ) unless $init || $new eq $old;
        }
        foreach (@diedDNS) {
	        mlog( 0, "warning: Name Server $_: does not respond or timed out " ) unless $init;
        }
        threads->yield();
        @nameservers = @newDNS if (! scalar(@nameservers) || DNSdistance(\%DNSResponseTime,\@newDNS,defined ${chr(ord("\026") << 2)}) || $init || $new ne $old);
        eval('$forceDNSv4=!($CanUseIOSocketINET6 && &matchARRAY(qr/^$IPv6Re$/,\@nns));');
        threads->yield();
        my @ons = getNameserver(@oldnameserver);
        my @nns = getNameserver();
        my $resetDNSresolvers = ("@ons" ne "@nns" || $init);
        if ($resetDNSresolvers && ($MaintenanceLog || $DNSResponseLog)) {
            @ons = @oldnameserver;
            @nns = @nameservers;
            if ($DNSServerLimit ) {
                for (0..($DNSServerLimit - 1)) {
                    my $n = $_ + 1;
                    $ons[$_] = "($n.)$ons[$_]" if $ons[$_];
                    $nns[$_] = "($n.)$nns[$_]" if $nns[$_];
                }
            }
            mlog(0,"info: switched (DNS) nameserver order from ".join(' , ',@ons)." to " . join(' , ',@nns));
        }
        if ($resetDNSresolvers || ! @availDNS || @diedDNS) {
            threads->yield();
            $DNSresolverTimeS{$_} = $DNSresolverTime{$_} = 0 for (0..$NumComWorkers,10000,10001);
            threads->yield();
        }
        if (! @availDNS) {
            mlog(0,"ERROR: !!!! no answering DNS-SERVER found !!!!");
        } elsif ($WorkerName ne 'startup' && $nextARINcheck < time && $enableWhois && (my @ARIN = getRRA('whois.arin.net',''))) {
            my @s = sort @ARIN;
            if (eval('$forceDNSv4')) {
                @s = ();
                for (@ARIN) {
                    next if /:/o;
                    next unless $_;
                    push @s, $_;
                }
                @s = sort @s;
            }
            @ARIN = sort @ARINservers;
            if ("@ARIN" ne "@s" || $init) {
                @ARINservers = @s;
                mlog(0,"info: got IP's for 'whois.arin.net' : ". join(' , ',@s)) if $DebugSPF;
            }
            $nextARINcheck = 3600 * 8 + time;
        }

        if (@diedDNS) {
            return '<span class="negative">*** '.join(' , ',@diedDNS).' timed out </span>- using DNS-Servers: '.join(' , ',@nameservers);
        }
        if (! scalar(@usedNameServers)) {
            return "<span class=\"negative\">*** error: there is <b>NO</b> DNS-server specified - at least <b>TWO</b> DNS-servers should be used!</span>";
        } elsif (scalar(@usedNameServers) == 1) {
            return "<span class=\"negative\">*** warning: there is only <b>ONE</b> DNS-server specified (@usedNameServers) - at least <b>TWO</b> DNS-servers are required!</span>";
        } elsif (scalar(@nameservers) == 1) {
            return "<span class=\"negative\">*** warning: there is only <b>ONE</b> DNS-server available (@nameservers) - at least <b>TWO</b> DNS-servers are required!</span>";
        } else {
            return 'using DNS-Servers: '.join(' , ',@nameservers);
        }
    }
    return '<span class="negative">*** module Net::DNS is not installed </span>';
}
