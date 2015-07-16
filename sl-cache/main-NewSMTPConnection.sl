#line 1 "sub main::NewSMTPConnection"
package main; sub NewSMTPConnection {
    my $client=shift;
    my $tclient = $Con{$client}->{self};
    if ($tclient) {
        $client = $tclient;
    } else {
        eval {
            threadConDone($client);
            delete $SocketCallsNewCon{$client};
            delete $SocketCalls{$client};
            close($client) if fileno($client);
        };
        return;
    }
    my $fnoC;
    my $fnoS;
    my $timeout;
    my $isSSL;
    my $isRemoteSupport;
    my ($server, $destination, $relayok, $AVa, $relayused);
    delete $SocketCallsNewCon{$client};
    delete $SocketCalls{$client};
    if ($RemoteSupportEnabled && $RemoteSupportEnabled eq ($Con{$client}->{peerhost} || $client->peerhost())) {

        # a Remote Support connection -- destination is the webAdminPort
        d('NewSMTPConnection - Remote Support');
        $isRemoteSupport = 1;
        $destination = $webAdminPort;
    } elsif(&matchFH($client,@lsnRelayI)) {

        # a relay connection -- destination is the relayhost if defined
        d('NewSMTPConnection - relay OK');
        $relayok=1;
        $relayused = 1;
        $destination = $relayHost ? $relayHost : $smtpDestination;
    } elsif(&matchFH($client,@lsn2I) && $smtpAuthServer ne '') {

        # connection on the Second Listen port
        d('NewSMTPConnection - AuthServer OK');
        $relayok=0;
        $destination=$smtpAuthServer;
    } elsif (&matchFH($client, @lsnSSLI) && $smtpDestinationSSL ne '' ) {

        # connection on the the secure SSL port
        d('NewSMTPConnection - SSL port');
        $destination = $smtpDestinationSSL;
        $relayok=0;
        $isSSL = 1;
    } else {
        d('NewSMTPConnection - no relay');
        $destination=$smtpDestination;
        $relayok=0;
        if(&matchFH($client,@lsnSSLI)) {
            $isSSL = 1;
        }
    }
    $fnoC = $Con{$client}->{fno} || fileno($client);
    my $ip = $Con{$client}->{peerhost} = $Con{$client}->{peerhost} || $client->peerhost()
       ||
       do { # this is somehow paranoid - here we should have a connected IP anyway
           mlog(0,sprintf("error: This system is some time unable to detect connected IP addresses - check that you use the latest C-library, Perl-version and Perl module versions - (%d)(%s)(%d)(%s)",$!,$!,$^E,$^E)) if $ConnectionLog;
           undef;
       };
    my $port     = $Con{$client}->{peerport} || $client->peerport();
    my $localip  = $client->sockhost();
    my $localport= $client->sockport();
    my $ret;

    if (! $ThreadDebug && $debugIP && (&matchIP($localip,'debugIP',0,0) || ($ip && &matchIP($ip,'debugIP',0,0)))) {
       $ThreadDebug = 1;
    }

    # shutting down ?
    if ($shuttingDown) {
        mlog(0,"connection from $ip:$port rejected -- shutdown/restart process is in progress");

        my $out = "421 <$myName> Service not available, closing transmission channel\r\n";
        &NoLoopSyswrite($client,$out,0) if $ip;
        threadConDone($client);
        delete $Con{$client};
        close($client);
        d('NewSMTPConnection - shutdown detected');
        return;
    }

    $Stats{smtpConnSSL}++ if $isSSL;
    $Con{$client}->{timestart} = Time::HiRes::time();

    # SSL error in the past
    if ($ip && $isSSL && $SSLfailed{$ip}) {
        mlog(0,"connection from $ip:$port rejected -- IP has failed SSL in the past");

        my $out = "421 <$myName> SSL-Service not available for IP $ip, closing transmission channel\r\n";
        &NoLoopSyswrite($client,$out,0) if $ip;
        threadConDone($client);
        delete $Con{$client};
        close($client);
        d('NewSMTPConnection - IP has failed SSL in the past');
        return;
    } elsif ($ip && $isSSL && exists $SSLfailed{$ip}) {
        delete $SSLfailed{$ip};
    }

    if ($ip && $EmergencyBlock{$ip}) {
        mlog( $client, "$ip:$port denied by internal EMERGENCY Blocker - this IP has possibly tried before to KILL assp" );
        mlog( $client, "$ip:$port ATTENTION ! The EMERGENCY blocking for this IP will be lifted after an SPAMBOX restart or at least in 15 minutes" );
        $Stats{denyConnectionA}++;
        $Con{$client}->{type} = 'C';
        &NoLoopSyswrite($client,"554 <$myName> Service denied, closing transmission channel\r\n",0);
        $Con{$client}->{error} = '5';
        done($client);
        return;
    }

    my $byWhatList = 'denySMTPConnectionsFromAlways';
    if ($ip && $denySMTPstrictEarly) {
        $ret = matchIP( $ip, 'denySMTPConnectionsFromAlways', $client,0 );
        $ret = matchIP( $ip, 'droplist', $client,0 ) if (! $ret && ($DoDropList == 2 or $DoDropList == 3) && ($byWhatList = 'droplist')) ;
    }

    if ($ip &&
        $denySMTPstrictEarly &&
        $ret &&
        $DoDenySMTPstrict &&
        ! matchIP( $ip, 'noPB', 0, 1 ) &&
        ! matchIP( $ip, 'noBlockingIPs', 0, 1 )
        )
    {
        $Con{$client}->{prepend} = "[DenyStrict]";
        if ($DoDenySMTPstrict == 1) {
            mlog( $client, "$ip:$port denied by $byWhatList strict: $ret" )
              if $denySMTPLog || $ConnectionLog >= 2;
            $Stats{denyConnectionA}++;
            $Con{$client}->{type} = 'C';
            &NoLoopSyswrite($client,"554 <$myName> Service denied, closing transmission channel\r\n",0);
            $Con{$client}->{error} = '5';
            done($client);
            return;
        } elsif ($DoDenySMTPstrict == 2) {
            mlog( $client, "[monitoring] $ip:$port denied by $byWhatList strict: $ret" )
              if $denySMTPLog || $ConnectionLog >= 2;
            $Con{$client}->{prepend} = '';
        }
    }

    # ip connection limiting  parallel session
    my $doIPcheck;
    $maxSMTPipSessions=999 if (!$maxSMTPipSessions);
    if ( $ip &&
         ! matchIP($ip,'noMaxSMTPSessions',0,1) &&
         ($doIPcheck =
            ! $relayok &&
            ! matchIP($ip,'noProcessingIPs',0,1) &&
            ! matchIP($ip,'whiteListedIPs',0,1) &&
            ! matchIP($ip,'noDelay',0,1) &&
            ! matchIP($ip,'ispip',0,1) &&
            ! matchIP($ip,'acceptAllMail',0,1) &&
            ! matchIP($ip,'noBlockingIPs',0,1)
         )
       )
    {
        threads->yield;
        if (++$SMTPSessionIP{$ip} > $maxSMTPipSessions) {
            threads->yield;
            $SMTPSessionIP{$ip}--;
            threads->yield;
            d("limiting ip: $client");
            mlog(0,"limiting $ip connections to $maxSMTPipSessions") if $ConnectionLog >= 2 || $SessionLog;

            $Stats{smtpConnLimitIP}++;
            $Con{$client}->{messagereason}="limiting $ip connections to $maxSMTPipSessions";
            pbAdd( $client, $ip, 'iplValencePB', "LimitingIP" ) if ! matchIP($ip,'noPB',0,1);
            d('NewSMTPConnection - LimitingIP');
            $Con{$client}->{type} = 'C';
            $Con{$client}->{error} = '5';
            done($client);
            return;
        } else {
            $SMTPSession{$client}=1;
            threads->yield;
        }
    }

    if (! $ip ) {
        mlog(0,"error: unable to detect the remote connected IP address - localIP:port, $localip:$localport - remoteIP:port, $ip:$port - local-socket,$client");
        $Con{$client}->{type} = 'C';
        $Con{$client}->{error} = '5';
        done($client);
        return;
    }

    # check relayPort usage
    if ($relayused && $allowRelayCon && ! matchIP($ip,'allowRelayCon',0,1)) {
        $Con{$client}->{prepend} = "[RelayAttempt]";
        $Con{$client}->{type} = 'C';
        &NoLoopSyswrite($client,"554 <$myName> Relay Service denied for IP $ip, closing transmission channel\r\n",0);
        $Con{$client}->{error} = '5';
        mlog(0,"rejected relay attemp on allowRelayCon for ip $ip") if $ConnectionLog >= 2 || $SessionLog;
        done($client);
        $Stats{rcptRelayRejected}++;
        return;
    }

    my $bip = &ipNetwork( $ip, $PenaltyUseNetblocks);

    if (   $DelayIP
        && $DelayIPTime
  		&& $doIPcheck
    	&& ! $allTestMode
    	&& (my $pbval = [split(/\s+/o,$PBBlack{$bip})]->[3]) > $DelayIP
    	&& ( ! $DelayIPPB{$bip} || ($DelayIPPB{$bip} + $DelayIPTime > time))
        && $ip !~ /$IPprivate/o
        && ! exists $PBWhite{$bip}
        && ! matchIP( $ip, 'noPB', 0, 1 ) )
    {
        $DelayIPPB{$bip} = time unless $DelayIPPB{$bip};
        $Stats{delayConnection}++;
        $Con{$client}->{type} = 'C';
        &NoLoopSyswrite($client,"451 4.7.1 Please try again later\r\n",0);
        $Con{$client}->{error} = '5';
        done($client);
        mlog(0,"delayed ip $ip, because PBBlack($pbval) is higher than DelayIP($DelayIP)- last penalty reason was: " . [split(/\s+/o,$PBBlack{$bip})]->[5] , 1) if $ConnectionLog >= 2 || $SessionLog;
        return;
    } elsif (   $DelayIP
             && $DelayIPTime
       		 && $doIPcheck
    	     && !$allTestMode
             && $DelayIPPB{$bip}
             && $DelayIPPB{$bip} + $DelayIPTime <= time)
    {
        delete $DelayIPPB{$bip};
    }

    if ($MaxAUTHErrors &&
        $doIPcheck &&
        $AUTHErrors{$bip} > $MaxAUTHErrors
       )
    {
        d("NewSMTPConnection - AUTHError ip: $client");
        $Con{$client}->{prepend} = "[AUTHError]";
        mlog(0,"blocked $ip - too many AUTH errors ($AUTHErrors{$bip})") if $ConnectionLog >= 2 || $SessionLog;

        $Stats{AUTHErrors}++;
        $Con{$client}->{type} = 'C';
        &NoLoopSyswrite($client,"554 <$myName> Service denied for IP $ip (harvester), closing transmission channel\r\n",0);
        $Con{$client}->{error} = '5';
        done($client);
        return;
    }
    
    my $intentForIP;
    my $peerhost;
    my $peerport;
    foreach my $destinationA (split(/\s*\|\s*/o, $destination)) {
        my $useSSL;
        if ($destinationA =~ /^(_*INBOUND_*:)?(\d+)$/o){
            $localip = '127.0.0.1' if ($localip eq '0.0.0.0');
            $localip = '[::1]' if ($localip eq '::');
            if (exists $crtable{$localip}) {
                $destinationA=$crtable{$localip};
                $intentForIP = "X-Assp-Intended-For-IP: $localip\r\n";
            } else {
                $destinationA = $localip .':'.$2;
            }
        }
        if ($destinationA =~ /^SSL:(.+)$/oi) {
            $destinationA = $1;
            $useSSL = ' using SSL';
            if ($useSSL && ! $CanUseIOSocketSSL) {
                mlog(0,"*** SSL:$destinationA require IO::Socket::SSL to be installed and enabled, trying others...") ;
                $server = undef;
                $intentForIP = '';
                next;
            }
        }
        if (! $server) {
            d("try to connect to server at $destinationA$useSSL");
            mlog(0,"info: try to connect to server at $destinationA$useSSL") if $ConnectionLog >= 2;
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
                $server = IO::Socket::SSL->new(%parms)
            } else {
                $server = $CanUseIOSocketINET6
                          ? IO::Socket::INET6->new(Proto=>'tcp',PeerAddr=>$destinationA,Timeout=>2,&getDestSockDom($destinationA),&getLocalAddress('SMTP',$destinationA))
                          : IO::Socket::INET->new(Proto=>'tcp',PeerAddr=>$destinationA,Timeout=>2,&getLocalAddress('SMTP',$destinationA));
            }
            threads->yield;
            if(ref($server) && eval{$peerhost = $server->peerhost(); $peerport = $server->peerport();$peerhost && $peerport;} ) {
                $destination=$destinationA;
                d("connected to server $server at $peerhost:$peerport$useSSL");
                mlog(0,"info: connected to server at $peerhost:$peerport$useSSL") if $ConnectionLog >= 2;
                last;
            } elsif (ref($server)) {
                mlog(0,"*** $destinationA$useSSL - no peerhost information available, trying others...") ;
                eval {$server->close;};
                $server = undef;
                $intentForIP = '';
            } else {
                mlog(0,"*** $destinationA$useSSL didn't work, trying others...") ;
                $server = undef;
                $intentForIP = '';
            }
        }
    }
    if(! (ref($server) && $peerhost && $peerport)) {
        mlog(0,"error: couldn't create server socket to $destination -- aborting connection") ;
        threads->yield;
        if (exists $SMTPSession{$client}) {
            $SMTPSessionIP{Total}++;
            threads->yield;
            $smtpConcurrentSessions++;
            threads->yield;
        }
        $Con{$client}->{type} = 'C';
        &NoLoopSyswrite($client,"421 <$myName> service temporarily unavailable, closing transmission\r\n",0);
        done($client);
        return;
    }
    if (! $ThreadDebug && &matchIP($peerhost,'debugIP',0,0)) {
       $ThreadDebug = 1;
    }
    $fnoS = fileno($server);
    if ($isRemoteSupport) {
        addProxyfh($client,$server);
        mlog(0,"Connected: remote support session: started from $ip:$port - the connection is moved to transparent proxy mode");
    } else {
        addfh($client,\&getline,$server);
        if($sendNoopInfo) {
            addfh($server,\&skipok,$client);
        } else {
            addfh($server,\&reply,$client);
        }
    }
    if ($ConTimeOutDebug) {
        my $m = &timestring();
        $Con{$client}->{contimeoutdebug}  = "$m $WorkerName\r\n";
        $Con{$client}->{contimeoutdebug} .= "$m client filenumber = $fnoC\r\n";
        $Con{$client}->{contimeoutdebug} .= "$m server filenumber = $fnoS\r\n";
        $Con{$client}->{contimeoutdebug} .= "$m client  = $client\r\n";
        $Con{$client}->{contimeoutdebug} .= "$m client IP  = $ip\r\n";
        $Con{$client}->{contimeoutdebug} .= "$m server  = $server\r\n";
    }
    $Con{$client}->{SessionID} = uc "$client";
    $Con{$client}->{SessionID} =~ s/^.+?\(0[xX]([^\)]+)\).*$/$1/o;
    $Con{$client}->{prescore} = 0;
    $Con{$client}->{debug}    = $ThreadDebug;
    $Con{$client}->{client}   = $client;
    $Con{$client}->{self}     = $client;
    $Con{$client}->{server}   = $server;
    $Con{$client}->{ip}       = $ip;
    $Con{$client}->{port}     = $port;
    $Con{$client}->{localip}  = $localip;
    $Con{$client}->{localport}= $localport;
    $Con{$client}->{relayok}  = $relayok;
    $Con{$client}->{myheaderCon} .= $intentForIP if $intentForIP;
    $Con{$client}->{myheaderCon} .= "X-Assp-Client-SSL: yes\r\n" if $isSSL;
    $Con{$client}->{chainMailInSession} = -1;
    $Con{$client}->{type}     = 'C';
    $Con{$client}->{fno}      = $fnoC;
    $Con{$server}->{type}     = 'S';
    $Con{$server}->{fno}      = $fnoS;
    $Con{$server}->{self}     = $server;
    $Con{$server}->{debug}    = $ThreadDebug;

    #  mlog(0,"connection fno : client = $fnoC , server = $fnoS");
    d("Connected: SID=$Con{$client}->{SessionID} $client -- $server");
    $Con{$client}->{acceptall} = 1 if matchIP($ip,'acceptAllMail',$client,0);
    if( $Con{$client}->{acceptall} || $Con{$client}->{relayok} || isOk2Relay($client,$ip) ) {
        $Con{$client}->{relayok} = 1;
        d("$client relaying ok: $ip");
    }
    my $time=$UseLocalTime ? localtime() : gmtime();
    my $tz=$UseLocalTime ? tzStr() : '+0000';
    $time=~s/... (...) +(\d+) (........) (....)/$2 $1 $4 $3/o;
    $Con{$client}->{rcvd}="Received: from =host ([$ip] helo=) by $myName with *SMTP* ($version); $time $tz\r\n";
    d("* connect SID=$Con{$client}->{SessionID} ip=$Con{$client}->{ip} relay=<$Con{$client}->{relayok}> *");
    my $text = $destination;
    $text = $server->sockhost() . ':' . $server->sockport() . " > $text , $fnoC-$fnoS" if $ConnectionLog >= 2;
    mlog(0,"Connected: session:$Con{$client}->{SessionID} $ip:$port > $localip:$localport > $text") if ($ConnectionLog && ! matchIP($ip,'noLog',0,1));
    $Con{$server}->{noop}="NOOP Connection from: $ip, $time $tz relayed by $myName\r\n" if $sendNoopInfo;

    # overall session limiting
    my $numsess;
    threads->yield;
    $numsess = ++$SMTPSessionIP{Total};
    threads->yield;
    $smtpConcurrentSessions++;
    threads->yield;
    $SMTPSession{$client}=$client;
    if ($maxSMTPSessions && $numsess>=$maxSMTPSessions) {
        d("$WorkerName limiting sessions: $client");
        if ($SessionLog) {
            mlog(0,"connected: $ip:$port") if !$ConnectionLog || matchIP($ip,'noLog',0,1); # log if not logged earlier
            mlog(0,"limiting total connections");
        }
        $Stats{smtpConnLimit}++;
    } else {      # increment Stats if connection not limited
        if (matchIP($ip,'noLog',0,1)) {
            $Stats{smtpConnNotLogged}++;
        } else {
            $Stats{smtpConn}++;
        }
    }
    if ($smtpConcurrentSessions>$Stats{smtpMaxConcurrentSessions}) {
        $Stats{smtpMaxConcurrentSessions}=$smtpConcurrentSessions;
    }
    newCrashFile($client);
}
