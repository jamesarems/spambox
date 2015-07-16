#line 1 "sub main::forwardSpam"
package main; sub forwardSpam {
    my ($from,$to,$oldfh)=@_;
    my $s;
    my $AVa;

    my $destination;
    if ($sendAllDestination ne '') {
        $destination = $sendAllDestination;
    }else{
        $destination = $smtpDestination;
    }

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
        mlog(0,"error: couldn't create server socket to $destination -- aborting sendAllSpam connection") if $SessionLog;
        return;
    }
    addfh($s,\&FShelo);
    my $this=$Con{$s};
    $this->{to_as} = $to;
    mlog($oldfh,"info: forwarding spam message to $this->{to_as}") if $ConnectionLog > 1;
    @{$this->{to}}=split(/\s*,\s*|\s+/o,$to);
    $this->{from}=$from;
    $this->{fromIP}=$Con{$oldfh}->{ip};
    $this->{clamscandone}=$Con{$oldfh}->{clamscandone};
    $this->{rcpt}=$Con{$oldfh}->{rcpt};
    $this->{myheader}=$Con{$oldfh}->{myheader};
    $this->{prepend}=$Con{$oldfh}->{prepend};
    $this->{saveprepend}=$Con{$oldfh}->{saveprepend};
    $this->{saveprepend2}=$Con{$oldfh}->{saveprepend2};
    $this->{body} = '';
    $this->{FSnoopCount} = 0;
    $this->{self} = $s;
    $this->{isreport} = 'FW-SPAM';
    return $s;
}
