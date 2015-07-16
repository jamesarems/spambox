#line 1 "sub main::closeAllWEBListeners"
package main; sub closeAllWEBListeners {
        mlog(0,"info: removing all WEB listeners");
        foreach my $lsn (@StatSocket ) {
            eval{close($lsn);} if $lsn;
        }

        foreach my $lsn (@WebSocket ) {
            eval{close($lsn);} if $lsn;
        }
        return 1;
}
