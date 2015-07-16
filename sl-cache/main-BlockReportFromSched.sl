#line 1 "sub main::BlockReportFromSched"
package main; sub BlockReportFromSched {
    my $parm = shift;
    open( my $tmpfh, '<', \$parm );
    $Con{$tmpfh} = {};
    BlockReportGen( '1', $tmpfh );
    delete $Con{$tmpfh};
}
