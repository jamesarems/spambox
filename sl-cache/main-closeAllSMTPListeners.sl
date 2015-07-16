#line 1 "sub main::closeAllSMTPListeners"
package main; sub closeAllSMTPListeners {
        mlog(0,"info: removing all SMTP and Proxy listeners");
        foreach my $lsn (@lsn ) {
            eval{close($lsn);} if $lsn;
        }

        foreach my $lsn (@lsn2 ) {
            eval{close($lsn);} if $lsn;
        }

        foreach my $lsn (@lsnSSL ) {
            eval{close($lsn);} if $lsn;
        }

        foreach my $lsn (@lsnRelay ) {
            eval{close($lsn);} if $lsn;
        }

        while (my ($k,$v) = each(%Proxy)) {
            eval{close($ProxySocket{$k});};
        }
        return 1;
}
