#line 1 "sub main::BlockReportFromQ"
package main; sub BlockReportFromQ {
    my $parm = shift;
    my $fh = Time::HiRes::time();    # a dummy $fh for a dummy $Con{$fh}
    $Con{$fh} = {};

    (   $Con{$fh}->{mailfrom},
        $Con{$fh}->{rcpt},
        $Con{$fh}->{ip},
        $Con{$fh}->{cip},
        $Con{$fh}->{header}
    ) = split( /\x00/o, $parm );
    $Con{$fh}->{blqueued} = 1;
    mlog( 0,"info: processing queued blocked mail request from $Con{$fh}->{mailfrom}")
      if $ReportLog >= 2 or $MaintenanceLog;
    &BlockReportBody( $fh, ".\r\n" );
    delete $Con{$fh};
}
