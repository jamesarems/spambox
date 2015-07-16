#line 1 "sub main::AdminReportMail"
package main; sub AdminReportMail {
    my($sub,$bod,$to)=@_;
    d('AdminReportMail');
    return if !$to;
    $to = &batv_remove_tag(0,$to,'');
    my $destination;
    my $s;
    my $AVa;
    if ($EmailReportDestination ne '') {
        $destination = $EmailReportDestination;
    }else{
        $destination = $smtpDestination;
    }

    &sigoffTry(__LINE__);
    $AVa = 0;
    foreach my $destinationA (split(/\s*\|\s*/o, $destination)) {
        my $useSSL;
        if ($destinationA =~ /^(_*INBOUND_*:)?(\d+)$/o){
            $destinationA = ($CanUseIOSocketINET6 ? '[::1]:' : '127.0.0.1:').$2;
        }
        if ($destinationA =~ /^SSL:(.+)$/oi) {
            $destinationA = $1;
            $useSSL = ' using SSL';
            if ($useSSL && ! $CanUseIOSocketSSL) {
                mlog(0,"*** SSL:$destinationA require IO::Socket::SSL to be installed and enabled, trying others...") ;
                $s = undef;
                next;
            }
        }
        if ($AVa<1) {
            if ($useSSL) {
                my %parms = getSSLParms(0);
                $parms{SSL_startHandshake} = 1;
                my ($interface,$p)=$destinationA=~/($HostRe):($PortRe)$/o;
                if ($interface) {
                    $parms{PeerHost} = $interface;
                    $parms{PeerPort} = $p;
                    $parms{LocalAddr} = getLocalAddress('SMTP',$interface);
                    delete $parms{LocalAddr} unless $parms{LocalAddr};
                } else {
                    $parms{PeerHost} = $destinationA;
                }
                $s = IO::Socket::SSL->new(%parms)
            } else {
                $s = $CanUseIOSocketINET6
                     ? IO::Socket::INET6->new(Proto=>'tcp',PeerAddr=>$destinationA,Timeout=>2,&getDestSockDom($destinationA),&getLocalAddress('SMTP',$destinationA))
                     : IO::Socket::INET->new(Proto=>'tcp',PeerAddr=>$destinationA,Timeout=>2,&getLocalAddress('SMTP',$destinationA));
            }
            if(ref($s)) {
                $AVa=1;
                $destination=$destinationA;
            }
            else {
                mlog(0,"*** $destinationA$useSSL didn't work, trying others...") if $SessionLog;
            }
        }

    }
    if(! ref($s)) {
        mlog(0,"error: couldn't create server socket to $destination -- aborting  connection adminreport ");
        &sigonTry(__LINE__);
        return;
    }
    addfh($s,\&RMhelo);
    my $this=$Con{$s};
    $this->{to}=$to;
    $this->{from}=$EmailFrom;

    local $/="\n";

    $this->{subject}=$sub;
    $this->{subject}=~s/\r?\n?//go;
    undef $/;

    $this->{body} = ref $bod ? $$bod : $bod;
    $this->{body} =~ s/[\r\n\.]+$//o;
    $this->{isreport} = 'REPORT';

    &sigonTry(__LINE__);
}
