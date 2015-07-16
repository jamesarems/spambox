#line 1 "sub main::BlockReportFwFromQ"
package main; sub BlockReportFwFromQ {
    my $parm = shift;

    my $this = {};
    (my $fh, my $fhost, my $host,$this->{mailfrom},$this->{rcpt},$this->{ip},$this->{cip},$this->{header}) = split( /\x00/o, $parm );
    if (! exists($BlockRepForwQueue{"$fh"})) {
        $BlockRepForwQueue{"$fh"} = {};
        $BlockRepForwQueue{"$fh"}->{'BlockRepForwHosts'} = {};
    }
    $BlockRepForwQueue{"$fh"}->{$_} = $this->{$_} for ('mailfrom','ip','cip','rcpt','header');
    $BlockRepForwQueue{"$fh"}->{'BlockRepForwHosts'}->{$fhost} = $host;
    $BlockRepForwQueue{"$fh"}->{'BlockRepForwNext'} = time + 300;
    $nextBlockRepForwQueue = $BlockRepForwQueue{"$fh"}->{'BlockRepForwNext'} if $nextBlockRepForwQueue > $BlockRepForwQueue{"$fh"}->{'BlockRepForwNext'};
    $BlockRepForwQueue{"$fh"}->{'BlockRepForwReTry'}++;
    mlog( 0,"info: queued failed forwarding BlockReport or resend request , from $Con{$fh}->{mailfrom} to host $fhost/$host")
      if $ReportLog >= 2 or $MaintenanceLog;
}
