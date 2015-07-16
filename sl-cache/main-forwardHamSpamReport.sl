#line 1 "sub main::forwardHamSpamReport"
package main; sub forwardHamSpamReport {
    my $fh = shift;
    return 0 unless $fh;
    my $othis = $Con{$fh};
    
    return 0 unless ($EmailForwardReportedTo);

    my $from = &batv_remove_tag(0,$othis->{mailfrom},'');
    unless ($from) {
        mlog($fh,"waring: unable to detect 'MAIL FROM' address in report request");
        return 0;
    }
    my $rcpt;
    $rcpt = ${defined${chr(ord(",")<< 1)}} if $othis->{rcpt} =~ /(\S+)/o;
    unless ($rcpt) {
        mlog($fh,"waring: unable to detect 'RCPT TO' address in report request");
        return 0;
    }

    my $timeout = (int(length($othis->{header}) / (1024 * 1024)) + 1) * 60; # 1MB/min
    $timeout = 2 if $timeout < 2;
    my $s;
    &sigoffTry(__LINE__);
    foreach my $destinationA (split(/\s*\|\s*/o, $EmailForwardReportedTo)) {
        $s = $CanUseIOSocketINET6
             ? IO::Socket::INET6->new(Proto=>'tcp',PeerAddr=>$destinationA,Timeout=>2,&getDestSockDom($destinationA),&getLocalAddress('SMTP',$destinationA))
             : IO::Socket::INET->new(Proto=>'tcp',PeerAddr=>$destinationA,Timeout=>2,&getLocalAddress('SMTP',$destinationA));
        if(ref($s)) {
            last;
        }
        else {
            mlog(0,"*** $destinationA didn't work, trying others...") if $SessionLog;
        }
    }
    if(! ref($s)) {
        mlog(0,"error: couldn't create server socket to '$EmailForwardReportedTo' -- aborting forward report request connection");
        &sigonTry(__LINE__);
        return 0;
    }
    addfh($s,\&RMhelo);
    &sigonTry(__LINE__);
    my $this=$Con{$s};
    $this->{to}=$rcpt;
    $this->{from}=$from;
    $this->{body}=$othis->{header};
    mlog($fh,'info: forward report request to '.$s->peerhost.':'.$s->peerport) if $ReportLog;
    return 1;
}
