#line 1 "sub main::BlockReportForwardRequest"
package main; sub BlockReportForwardRequest {
    my ($fh, $host) = @_;
    my $this = $Con{$fh};
    d("BlockReportForwardRequest - $host");

    if ( $BlockRepForwHost && ! $CanUseNetSMTP ) {
        mlog(0,"error: unable to forward blocked mail request - module Net::SMTP is not installed and/or enabled") if $ReportLog;
        return;
    }
    
    if ( $BlockRepForwHost && $CanUseNetSMTP ) {
        my $smtp;
        my $MTAip;
        my $port;
        my $ip;
        my $hostip;
        my $fwhost = $BlockRepForwHost;

        $host =~ s/\s//go;
        if ($host && $host !~ /$IPRe/o ) {
            eval {
                my $pip = gethostbyname($host);
                if ( defined $pip ) {
                    $hostip = inet_ntoa($pip);
                }
            };
            mlog( 0,"info: forwarding blocked mail request - resolved ip $hostip for host $host") if $ReportLog >= 2;
        }

        if ( ($hostip && $BlockRepForwHost =~ /\s*(SSL:)?(\Q$hostip\E)\s*:\s*(\d+)\s*/i) or
             ($host && $BlockRepForwHost =~ /\s*(SSL:)?(\Q$host\E)\s*:\s*(\d+)\s*/i) ) {
                $fwhost = "$2:$3";
                mlog( 0,"info: got forwarding blocked mail request from $this->{mailfrom} to host $fwhost") if $ReportLog >= 2;
        }

        foreach my $MTA ( split( /\s*\|\s*/o, $fwhost ) ) {
            my ($useSSL,$TLS);
            $MTA =~ s/\s//go;
            $useSSL = $MTA =~ s/^SSL://o;
            if ($useSSL && ! $CanUseNetSMTPSSL) {
                mlog(0,"warning: blockreport forwarding to $MTA requires the missing Perl module Net::SMTP::SSL - skip forwarding");
                next;
            }
            ( $MTAip, $port ) = split( /\:/o, $MTA );
            my $fhost = $MTAip;
            if ( $MTAip !~ /$IPRe/o ) {
                eval {
                    my $pip = gethostbyname($MTAip);
                    $ip = inet_ntoa($pip) if ( defined $pip );
                };
            }
            $MTAip = $ip ? $ip : $MTAip;
            if ( $this->{ip} eq $MTAip or $this->{cip} eq $MTAip ) {
                mlog( 0,"info: skip forwarding blocked mail request from $this->{mailfrom} to host $MTA - request comes from this host")
                  if $ReportLog >= 2;
                next;
            }
            my $mod = ($useSSL ? 'Net::SMTP::SSL' : 'Net::SMTP');
            if (    $DoTLS == 2
                && ! $useSSL
                && ! exists $localTLSfailed{$MTA}
                && ! matchIP($MTAip,'noTLSIP',undef,1)
               )
            {
                mlog(0,"BlockReport-forward: will try to use STARTTLS to $MTA") if $ConnectionLog >= 2;
                $TLS = 1;
            }
            my %sslargs = $useSSL ? getSSLParms(0) : () ;
            $sslargs{SSL_startHandshake} = 1 if $useSSL;
            $port ||= 25;
            eval {
                $smtp = $mod->new(
                    $fhost,
                    Port    => $port,
                    Hello   => $myName,
                    Debug => ($TLS ? $SSLDEBUG : $debug),
                    Timeout => (($TLS || $useSSL) ? max($SSLtimeout,10) : 120),   # 120 is the default in Net::SMTP
                    sslParms => \%sslargs,
                    getLocalAddress('SMTP',$fhost)
                );
                if ($smtp) {
                    if ($TLS) {
                        eval{$smtp->starttls();};
                        $localTLSfailed{$MTA} = time if ($@);
                    }
                    $smtp->mail( $this->{mailfrom} );
                    $smtp->to( $this->{rcpt} );
                    $smtp->data();
                    my $timeout = (int(length($this->{header}) / (1024 * 1024)) + 1) * 60; # 1MB/min
                    my $blocking = $smtp->blocking(0);
                    my $data = $this->{header};
                    $data =~ s/\.[\r\n]+$//o;
                    NoLoopSyswrite($smtp, $data, $timeout);
                    $smtp->blocking($blocking);
                    $smtp->dataend();
                    $smtp->quit;
                }
            };
            if ( $smtp && !$@ ) {
                mlog( 0,"info: forwarded blocked mail request from $this->{mailfrom} to host $MTA") if $ReportLog >= 2;
                if ($WorkerNumber == 10000) {
                    if (exists $BlockRepForwQueue{"$fh"}) {
                        if (scalar keys(%{$BlockRepForwQueue{"$fh"}->{'BlockRepForwHosts'}})) {
                            delete $BlockRepForwQueue{"$fh"}->{'BlockRepForwHosts'}->{$fhost};
                            delete $BlockRepForwQueue{"$fh"} unless scalar keys(%{$BlockRepForwQueue{"$fh"}->{'BlockRepForwHosts'}});
                        } else {
                            delete $BlockRepForwQueue{"$fh"};
                        }
                    }
                }
            } else {
                mlog( 0,"error: unable to forward blocked mail request from $this->{mailfrom} to host $MTA - $@") if $ReportLog && $WorkerNumber < 10000;
                if ($WorkerNumber == 10000) {
                    if (! exists($BlockRepForwQueue{"$fh"})) {
                        $BlockRepForwQueue{"$fh"} = {};
                        $BlockRepForwQueue{"$fh"}->{'BlockRepForwHosts'} = {};
                    }
                    $BlockRepForwQueue{"$fh"}->{$_} = $this->{$_} for ('mailfrom','ip','cip','rcpt','header');
                    $BlockRepForwQueue{"$fh"}->{'BlockRepForwHosts'}->{$fhost} = $host;
                    $BlockRepForwQueue{"$fh"}->{'BlockRepForwNext'} = time + 300;
                    $nextBlockRepForwQueue = $BlockRepForwQueue{"$fh"}->{'BlockRepForwNext'} if $nextBlockRepForwQueue > $BlockRepForwQueue{"$fh"}->{'BlockRepForwNext'};
                    $BlockRepForwQueue{"$fh"}->{'BlockRepForwReTry'}++;
                    my $what = (++$BlockRepForwQueue{"$fh"}->{'BlockRepForwReTry'}) % 3 ? 'warning' : 'error';
                    mlog( 0,"$what: still unable to forward blocked mail request from $this->{mailfrom} to host $MTA - $@") if $ReportLog;
                } else {
                    ReturnMail($fh,$this->{mailfrom},"$base/$ReportFiles{BlockRepForwHost}","forward resend request queued for host ($host)",\"\nrequest received on: $myName\ncurrently unreachable host: $fhost\n");
                    my $parm = "$fh\x00$fhost\x00$host\x00$this->{mailfrom}\x00$this->{rcpt}\x00$this->{ip}\x00$this->{cip}\x00$this->{header}";
                    &cmdToThread( '10000BlockReportFwFromQ', $parm );
                }
            }
        }
    }
}
