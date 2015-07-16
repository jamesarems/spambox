#line 1 "sub main::BackSctrDNS"
package main; sub BackSctrDNS {
    my ($fh,$ip) = @_;
    d('BackSctrDNS');

    &sigoff(__LINE__);
    my $backsctr = eval {
        RBL->new(
            reuse       => ($DNSReuseSocket?'RBLobj':undef),
            lists       => [@backsctrlist],
            server      => \@nameservers,
            max_hits    => 1,
            max_replies => 1,
            query_txt   => 0,
            max_time    => 30,
            timeout     => $DNStimeout,
            tolog       => $BacksctrLog>=2 || $DebugSPF
        );
    };

    # add exception check
    if ($@ || ! ref($backsctr)) {
        &sigon(__LINE__);
        mlog($fh,"BackSctrDNS: error - $@" . ref($backsctr) ? '' : " - $backsctr");
        return;
    }
    my $lookup_return = eval{$backsctr->lookup($ip,"BACKSCATTER");};
    &sigon(__LINE__);
    mlog($fh,"error: Backscatterer-DNS check failed : $lookup_return") if ($lookup_return && $lookup_return ne 1);
    mlog($fh,"error: Backscatterer-DNS lookup failed : $@") if ($@);
    return if ($lookup_return ne 1);
    my @listed_by = eval{$backsctr->listed_by();};
    return @listed_by;
}
