#line 1 "sub main::pollerror"
package main; sub pollerror {
    my $action = shift;
    
    my $what = $action eq $readable ? 'read' : 'write';
    
    my %calls = (
        \&ConToThread       => 'ConToThread',
        \&NewWebConnection  => 'NewWebConnection',
        \&NewStatConnection => 'NewStatConnection',
        \&WebTraffic        => 'WebTraffic',
        \&StatTraffic       => 'StatTraffic',
        \&ProxyTraffic      => 'ProxyTraffic',
        \&SMTPTraffic       => 'SMTPTraffic'
    );
    my @errfh;
    my @nvalfh;

    if ($IOEngineRun == 0) {
        @errfh = $action->handles(POLLERR);
        @nvalfh = $action->handles(POLLNVAL);
    } else {
        @errfh = $action->has_exception($pollwait);
    }

    my $numerr = scalar(@errfh);
    my $numnval = scalar(@nvalfh);
    return $numerr + $numnval unless $numerr + $numnval;
    mlog(0,"error: IO-subsystem error - $numerr error state $what handles") if (($numerr && $ConnectionLog == 3) || $debug || $ThreadDebug);
    mlog(0,"error: IO-subsystem error - $numnval wrong $what handles") if (($numnval && $ConnectionLog == 3) || $debug || $ThreadDebug);
    my %ErrorFH = ();
    foreach my $fh (@errfh) {
        $ErrorFH{$fh} = ' - error state';
    }
    foreach my $fh (@nvalfh) {
        $ErrorFH{$fh} .= ' - invalid filedescriptor';
        push @errfh,$fh;
    }
    foreach my $fh (@errfh) {
        my $fhcon;
        my $peercon;
        my $fno;
        my $ip;
        eval{$fhcon = $fh->sockhost().":".$fh->sockport();};
        $fhcon = 'n/a' unless $fhcon;
        eval{$ip = $fh->peerhost();$peercon = $ip.":".$fh->peerport();};
        $peercon = 'n/a' unless $peercon;
        my $calltarget = $calls{$SocketCalls{$fh}};
        eval{$fno = fileno($fh);};
        mlog(0,"error: registered fd for $fh is not equal$ErrorFH{$fh}") if ($ConnectionLog == 3 && $fno && $Fileno{$fno} && $Fileno{$fno} ne $fh);
        mlog(0,"error: IO-handle : $fh;  fileno : $fno; call : $calltarget; localIP : $fhcon; peerIP : $peercon;$ErrorFH{$fh}; - will remove handle") if $ConnectionLog == 3;
        done($fh) if $CloseHandleOnPollError;
    }
    return $numerr + $numnval;
}
