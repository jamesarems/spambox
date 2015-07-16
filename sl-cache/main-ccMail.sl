#line 1 "sub main::ccMail"
package main; sub ccMail {
    my($fh,$from,$to,$bod,$sub,$rcpt)=@_;
    my $this=$Con{$fh};
    my $s;
    my $AVa;
    $from = batv_remove_tag(0,$from,'');
    return if !$sendHamInbound && !$sendHamOutbound;
    if ($sendHamOutbound && $this->{relayok} && (!$ccHamFilter || allSL($rcpt,$from,'ccHamFilter'))  && ! allSL($rcpt,$from,'ccnHamFilter')) {
        $to=$sendHamOutbound;
    } elsif($sendHamInbound && !$this->{relayok} && (!$ccHamFilter || allSL($rcpt,$from,'ccHamFilter')) && ! allSL($rcpt,$from,'ccnHamFilter')) {
        $to=$sendHamInbound;

    } else {
        return;
    }

    #return if($sub!~/Received/io);

    my ($current_username,$current_domain);
    ($current_username,$current_domain) = ($1,$2) if $rcpt =~/($EmailAdrRe)\@($EmailDomainRe)/o;
    my $cchamlt = $to;
    $cchamlt =~ s/USERNAME/$current_username/go;
    $cchamlt =~ s/DOMAIN/$current_domain/go;

    if ($ccMailReplaceRecpt && $ReplaceRecpt) {
          my $newcchamlt = RcptReplace($cchamlt,$from,'RecRepRegex');
          if (lc $newcchamlt ne lc $cchamlt) {
              $cchamlt = $newcchamlt;
              mlog($fh,"info: ccMail recipient $cchamlt replaced with $newcchamlt");
          }
    }

    my $destination;
    if ($sendAllHamDestination ne '') {
        $destination = $sendAllHamDestination;
    } elsif ($sendAllDestination ne '') {
        $destination = $sendAllDestination;
    } else {
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
        mlog(0,"error: couldn't create server socket to $destination -- aborting  connection ccmail");
        return;
    }
    addfh($s,\&CChelo);
    $this=$Con{$s};
    $this->{to}=$cchamlt;
    $this->{from}=$from;
    $this->{fromIP} = $Con{$fh}->{ip};
    
    local $/="\n";

    $this->{subject}= ref $sub ? $$sub : $sub;
    $this->{subject}=~s/\r?\n?//go;
    undef $/;

    $this->{body} = ref $bod ? $$bod : $bod;
    $this->{body} =~ s/\r?\n/\r\n/gos;
    $this->{body} =~ s/[\r\n\.]$//o;
    $this->{isreport} = 'CC-MAIL';

    my $clamavbytes = $ClamAVBytes ? $ClamAVBytes : 50000;
    $clamavbytes = 100000 if $ClamAVBytes>100000;
    $this->{mailfrom} = $this->{from};
    $this->{ip} = $this->{fromIP};
    $this->{overwritedo} = 1;
    if ($ScanCC &&
           $this->{body}  &&
           ((haveToScan($s) && ! ClamScanOK($s,\substr($this->{body},0,$clamavbytes))) or
            (haveToFileScan($s) && ! FileScanOK($s,\substr($this->{body},0,$clamavbytes)))
           )
       ) {
       delete $this->{mailfrom};
       delete $this->{ip};
       delete $this->{overwritedo};
       mlog($fh,"info: skip forwarding message to $this->{to_as} - virus found") if $ConnectionLog;
       @{$Con{$s}->{to}} = (); undef @{$Con{$s}->{to}};
       done2($s);
       return;
    }
    delete $this->{mailfrom};
    delete $this->{ip};
    delete $this->{overwritedo};
}
