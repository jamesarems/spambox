#line 1 "sub main::BlockReportSend"
package main; sub BlockReportSend {
    my ( $fh, $to, $for, $subject, $bod ) = @_;

    my $RM;
    my $this     = $Con{$fh};
    my $mailfrom = $this->{mailfrom};

    $mailfrom = $EmailFrom if ( lc $mailfrom eq lc $EmailAdminReportsTo );

    if (! $CanUseNetSMTP) {
        mlog(0,"error: Perl module Net::SMTP is not installed or disabled in configuration - spambox is unable to send the BlockReport");
        return;
    }
    
    $bod     =~ s/\r?\n/\r\n/go;
    $subject =~ s/\r?\n?//go;

    my $destination;
    my $local = 1;
    if ( $EmailReportDestination ne '' ) {
        $destination = $EmailReportDestination;
    } else {
        $destination = $smtpDestination;
        if (! localmail($to) && $relayHost) {
            $destination = $relayHost;
            $local = 0;
        }
    }
    my $brmsgid = 'spambox_bl_'.time.'_'.rand(1000).'@'.$myName;

    my $smtp;
    my $SMTPMOD;
    my @failed;
    foreach my $MTA ( split( /\s*\|\s*/o, $destination ) ) {
        my $useSSL;
        if ( $MTA =~ /^(_*INBOUND_*:)?(\d+)$/o ) {
            $MTA = ($CanUseIOSocketINET6 ? '[::1]:' : '127.0.0.1:').$2;
        }
        my %sslargs;
        if ($MTA =~ /^SSL:(.+)$/oi) {
            $MTA = $1;
            $useSSL = ' using SSL';
            if ($useSSL && ! $CanUseNetSMTPSSL) {
                mlog(0,"*** SSL:$MTA require Net::SMTP::SSL and IO::Socket::SSL to be installed and enabled, trying others...") ;
                next;
            }
            %sslargs = getSSLParms(0);
            $sslargs{SSL_startHandshake} = 1;
        }

        my $TLS = 0;
        my ($mtaIP) = $MTA =~ /^($IPRe)/o;
        if (    $DoTLS == 2
            && ! $useSSL
            && ! exists $localTLSfailed{$MTA}
            && ! matchIP($mtaIP,'noTLSIP',$fh,1)
           )
        {
            mlog(0,"BlockReport-send: will try to use STARTTLS on connection to $MTA") if $ConnectionLog >= 2 || $ReportLog >= 2;
            $TLS = 1;
        }
        if ($useSSL) {
            $SMTPMOD = 'Net::SMTP::SSL';
        } else {
            $SMTPMOD = 'Net::SMTP';
        }
        my ($host,$port) = $MTA =~ /($HostRe)(?::($PortRe))?$/io;
        $port ||= 25;
        eval {
            $smtp = $SMTPMOD->new(
                $host,
                Port => $port,
                Debug => ($TLS || $useSSL ? $SSLDEBUG : $debug),
                Hello   => $myName,
                Timeout => (($TLS || $useSSL) ? max($SSLtimeout,10) : 120),   # 120 is the default in Net::SMTP
                sslParms => \%sslargs,
                getLocalAddress('SMTP',$host)
            );
            if ($smtp) {
                my $fh = $smtp;
                if ($TLS) {
                    eval{$smtp->starttls();};
                    $localTLSfailed{$MTA} = time if ($@);
                }
                my $timeout = (int(length($bod) / (1024 * 1024)) + 1) * 60; # 1MB/min
                $timeout = 2 if $timeout < 2;
                $smtp->auth($relayAuthUser,$relayAuthPass) if( ! $local && $relayAuthUser && $relayAuthPass);
                $smtp->mail($mailfrom);
                $smtp->to($to);
                $smtp->data();
                my $blocking = $fh->blocking(0);
                NoLoopSyswrite($fh,"To: $to\r\n",0) or die "$!\n";
                NoLoopSyswrite($fh,"From: $mailfrom\r\n",0) or die "$!\n";
                NoLoopSyswrite($fh,"Subject: $subject\r\n",0) or die "$!\n";
                NoLoopSyswrite($fh,"Message-ID: $brmsgid\r\n",0) or die "$!\n";
                NoLoopSyswrite($fh,$bod . "\r\n",$timeout) or die "$!\n";
                $fh->blocking($blocking);
                $smtp->dataend();
                $smtp->quit;
            } elsif (!$@) {
                $@ = 'unable to connect to host';
            }
        };
        if ( $smtp && !$@ ) {
            mlog( 0, "info: sent block report for $for to $to at $MTA$useSSL".($TLS?'(STARTTLS)':'') )
              if $ReportLog >= 2;
            last;
        }
        push(@failed,"error: couldn't send block report for $for to $to at $host:$port using $SMTPMOD".($TLS?'(STARTTLS)':'')." - $@");
    }
    if ( ! $smtp || $@ ) {
        for (@failed) {
            mlog( 0, $_,1);
        }
    }
}
