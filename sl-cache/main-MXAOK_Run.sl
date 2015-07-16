#line 1 "sub main::MXAOK_Run"
package main; sub MXAOK_Run {
    my $fh = shift;
    d('MXAOK');
    my $this = $Con{$fh};
    return 1 if $this->{MXAOK};
    $this->{MXAOK} = 1;

    $fh = 0 if "$fh" =~ /^\d+$/o;

    my $ip = $this->{ip};
    $ip = $this->{cip} if $this->{ispip} && $this->{cip};

    skipCheck($this,'ro','co','wl') && return 1;
    return 1 if ($this->{noprocessing} & 1);
    return 1 if $this->{isbounce};
#    return 1 if $this->{mailfrom} =~ /www|news|mail|noreply/io;
    return 1 if (($this->{rwlok} && ! $this->{cip}) or ($this->{cip} && pbWhiteFind($ip)));
    return 1 if ( localmail( $this->{mailfrom} ) );

    my $slok = $this->{allLoveMXASpam} == 1;

    my $mf   = lc $this->{mailfrom};
    my %mfd;
    if ($mf =~ /\@($EmailDomainRe)$/o) {
        $mfd{$1}->{mx} = $mfd{$1}->{a} = $mfd{$1}->{ctime} = undef;
        $mfd{$1}->{tag} = 'Mail From:';
    }
    while ($this->{header} =~ /($HeaderNameRe):($HeaderValueRe)/igos) {
        my ($tag,$line) = ($1,$2);
        next if $tag !~ /^(?:From|ReturnReceipt|Return-Receipt-To|Disposition-Notification-To|Return-Path|Reply-To|Sender|Errors-To|List-\w+)$/io;
        headerUnwrap($line);
        while ($line =~ /$EmailAdrRe\@($EmailDomainRe)/og) {
            my $dom = lc $1;
            next if localdomains('@'.$dom);
            $mfd{$dom}->{mx} = $mfd{$dom}->{a} = $mfd{$dom}->{ctime} = undef;
            $mfd{$dom}->{tag} .= $mfd{$dom}->{tag} ? " , $tag" : $tag;
        }
    }

    my $DoDomainCheck = $DoDomainCheck;
    $DoDomainCheck = 3 if (($switchSpamLoverToScoring && $DoPenaltyMessage && ( $slok || $this->{spamlover} & 1 ))
                         or
                           ($switchTestToScoring && $DoPenaltyMessage &&  ( $mxaTestMode || $allTestMode ))
                          );

    my $tlit;
    $tlit = &tlit($DoDomainCheck);
    $this->{prepend} = '';
    my $hasPrivat;
    my %queryError;

    mlog($fh,"checking MX/A for ".join(' , ',keys(%mfd))) if $ValidateSenderLog >= 2;

    DOMAIN:
    foreach my $mfd (keys %mfd) {
        my ( $cachetime, $mxexchange, $arecord ) = MXACacheFind($mfd);
        $cachetime = time if (! $cachetime && $this->{invalidSenderDomain} eq $mfd);
        if ( ! $cachetime ) {
            my $ans = queryDNS($mfd ,'MX');
            my @queryMX = ref($ans) ? sort { $a->preference <=> $b->preference } grep { $_->type eq 'MX'} $ans->answer
                                    : ();
            if (@queryMX) {
                MX:
                foreach my $rr ( @queryMX ) {
                    my @MXip;
                    eval{$mxexchange = $rr->exchange;} or next MX;
                    my @noIP;
                    if ($mxexchange =~ /^$IPRe$/o) {
                        if ($mxexchange !~ /$IPprivate/o) {
                            $mfd{$mfd}->{mx} = $mxexchange;
                            $mfd{$mfd}->{a} = $mxexchange;
                            $mfd{$mfd}->{ctime} = undef;
                            $queryError{$mfd} = undef;
                            $hasPrivat = 0;
                            next DOMAIN;
                        } elsif ($hasPrivat != 0) {
                            $hasPrivat = 1;
                            push @noIP, $mxexchange;
                        } else {
                            push @noIP, $mxexchange;
                        }
                        mlog( $fh,"$mfd - MX $mxexchange has a private IP (@noIP) - this MX has failed", 0)
                            if $ValidateSenderLog;
                        $mfd{$mfd}->{mx} = $mxexchange;
                        $mfd{$mfd}->{a} = $mfd{$mfd}->{ctime} = undef;
                        $queryError{$mfd} = undef;
                        next MX;
                    }
                    my $res6 = queryDNS($mxexchange ,'AAAA');
                    my $lde6 = $lastDNSerror;
                    my $res4 = queryDNS($mxexchange ,'A');
                    my $lde4 = $lastDNSerror;
                    $lastDNSerror = '' if (! $lde4 || ! $lde6);
                    if (ref($res4) || ref($res6)) {
                        my @answer;
                        push @answer , map{$_->string} grep { $_->type eq 'A'} $res4->answer if ref($res4);
                        push @answer , map{$_->string} grep { $_->type eq 'AAAA'} $res6->answer if ref($res6);
                        while (@answer) {
                            my $RR = Net::DNS::RR->new(shift @answer);
                            my $aip = eval{$RR->rdatastr};
                            mlog( $fh,"$mfd - MX '$mxexchange' - got IP ($aip)", 0)
                                if $ValidateSenderLog >= 2;
                            if ($aip) {
                                if ($aip !~ /$IPprivate/o) {
                                    push @MXip, $aip;
                                    $hasPrivat = 0;
                                    last;
                                } elsif ($hasPrivat != 0) {
                                    $hasPrivat = 1;
                                    push @noIP, $aip;
                                } else {
                                    push @noIP, $aip;
                                }
                            }
                        }
                    }
                    if (!@MXip && $lastDNSerror && $lastDNSerror ne 'NXDOMAIN' && $lastDNSerror ne 'NOERROR') {
                        mlog( $fh,"$mfd - MX $mxexchange - can't get DNS-server answer for A-record - ($lastDNSerror)", 0)
                            if $ValidateSenderLog;
                        $mfd{$mfd}->{mx} = $mxexchange;
                        $mfd{$mfd}->{a} = $mfd{$mfd}->{ctime} = undef;
                        $queryError{$mfd} = $lastDNSerror;
                    } elsif (!@MXip && ($lastDNSerror eq 'NXDOMAIN' || $lastDNSerror eq 'NOERROR')) {
                        mlog( $fh,"$mfd - MX $mxexchange has failed A-record ($lastDNSerror)", 0)
                            if $ValidateSenderLog;
                        $mfd{$mfd}->{mx} = $mxexchange;
                        $mfd{$mfd}->{a} = $mfd{$mfd}->{ctime} = undef;
                        $queryError{$mfd} = undef;
                    } elsif (@MXip && $mxexchange) {
                        $mfd{$mfd}->{mx} = $mxexchange;
                        $mfd{$mfd}->{a} = $MXip[0];
                        $mfd{$mfd}->{ctime} = undef;
                        $queryError{$mfd} = undef;
                        next DOMAIN;
                    } elsif (!@MXip && @noIP && $mxexchange) {
                        mlog( $fh,"$mfd - MX $mxexchange has a private IP (@noIP) - this MX has failed A-record ($lastDNSerror)", 0)
                            if $ValidateSenderLog;
                        $mfd{$mfd}->{mx} = $mxexchange;
                        $mfd{$mfd}->{a} = $mfd{$mfd}->{ctime} = undef;
                        $queryError{$mfd} = undef;
                    } elsif (!@MXip && ! @noIP && $mxexchange) {
                        mlog( $fh,"$mfd - MX $mxexchange has no IP address - this MX has failed A-record ($lastDNSerror)", 0)
                            if $ValidateSenderLog;
                        $mfd{$mfd}->{mx} = $mxexchange;
                        $mfd{$mfd}->{a} = $mfd{$mfd}->{ctime} = undef;
                        $queryError{$mfd} = undef;
                    }
                }
            } elsif ($lastDNSerror && $lastDNSerror ne 'NXDOMAIN' && $lastDNSerror ne 'NOERROR') {
                mlog( $fh,"$mfd - can't get DNS-server answer for MX - ($lastDNSerror)", 0)
                    if $ValidateSenderLog;
                $mfd{$mfd}->{mx} = $mfd{$mfd}->{a} = $mfd{$mfd}->{ctime} = undef;
                $queryError{$mfd} = $lastDNSerror;
            } else {
                mlog( $fh,"$mfd - no MX record found - ($lastDNSerror)", 0)
                    if $ValidateSenderLog;
                $mfd{$mfd}->{mx} = $mfd{$mfd}->{a} = $mfd{$mfd}->{ctime} = undef;
                $queryError{$mfd} = undef;
            }
        } else {
            $mfd{$mfd}->{mx} = $mxexchange;
            $mfd{$mfd}->{a} = $arecord;
            $mfd{$mfd}->{ctime} = $cachetime;
        }
    }

    my $mfailed;
    my $afailed;
    my $failed;
    my $mpb;
    my $apb;
    foreach my $mfd (keys %mfd) {

        if ($mfd{$mfd}->{mx}) {

            #MX found
            my $msg = "MX found";
            $msg .= " (cache)" if $mfd{$mfd}->{ctime};
            $msg .= ": $mfd ($mfd{$mfd}->{tag}) -> ". $mfd{$mfd}->{mx};
            mlog( $fh, $msg, 1, 1 )
              if $ValidateSenderLog >= 2 ;

        } elsif (! $queryError{$mfd}) {

            #MX not found
            $this->{prepend} = "[MissingMX]";
            $this->{messagereason} = "MX missing";
            $this->{messagereason} .= " (cache)" if $mfd{$mfd}->{ctime};
            $this->{messagereason} .= ": $mfd ($mfd{$mfd}->{tag})";

            mlog( $fh,"[$tlit] $this->{messagereason}", 0)
              if $ValidateSenderLog && ${'mxValencePB'}[0];

            pbWhiteDelete( $fh, $ip ) if ! $mpb && $fh;
            pbAdd( $fh, $ip, 'mxValencePB', 'MissingMX' ) if $DoDomainCheck != 2 && !$mpb && $fh;
            pbAdd( $fh, $ip, 'mxValencePB', 'MissingMX' ) if $DoDomainCheck != 2 && !$mpb && $hasPrivat && $fh;
            if (! $mfd{$mfd}->{a} ) {
                my ($name, $aliases, $addrtype, $length, @addrs);
                eval{
                    ($name, $aliases, $addrtype, $length, @addrs) = gethostbyname($mfd);
                };
                while (my $i = shift @addrs) {
                    my ($ad, $bd, $cd, $dd) = unpack('C4', $i);
                    my $arecord ="$ad.$bd.$cd.$dd";
                    if ( $MXACacheInterval > 0 && $arecord =~ /^$IPRe$/o && $arecord !~ /^$IPprivate$/o) {
                        $mfd{$mfd}->{a} = $arecord;
                        last;
                    }
                }
            }
            $mfailed = 1;
            $this->{prepend} = '';
        }

        if ($mfd{$mfd}->{a}) {

            #A  found
            my $msg = "A record found";
            $msg .= " (cache)" if $mfd{$mfd}->{ctime};
            $msg .= ": $mfd ($mfd{$mfd}->{tag}) -> ".$mfd{$mfd}->{a};
            mlog( $fh, $msg, 1, 1 )	if $ValidateSenderLog >= 2 ;

        } elsif (! $queryError{$mfd}) {

            #A not found
            $this->{prepend} = "[MissingMXA]";

            $this->{messagereason} = "A record missing: $mfd ($mfd{$mfd}->{tag})";
            $this->{messagereason} .= " (cache)" if $mfd{$mfd}->{ctime};

            mlog( $fh,"[$tlit] $this->{messagereason}")
              if $ValidateSenderLog && $DoDomainCheck >= 2;

            delayWhiteExpire($fh) if ! $apb && $fh;
            pbAdd( $fh, $ip, 'mxaValencePB', 'MissingMXA' ) if $DoDomainCheck != 2 && ! $apb && $fh;
            pbAdd( $fh, $ip, 'mxaValencePB', 'MissingMXA' ) if $DoDomainCheck != 2 && ! $apb && $hasPrivat && $fh;
            $this->{prepend} = '';
            $afailed = 1;
        }
        if ( $MXACacheInterval > 0 && ! $queryError{$mfd} && ! $mfd{$mfd}->{ctime}) {
            MXACacheAdd( $mfd, $mfd{$mfd}->{mx}, $mfd{$mfd}->{a} );
        }
        $this->{MXAres}->{$mfd} = { 'dom' => $mfd , 'mx' => $mfd{$mfd}->{mx}, 'a' => $mfd{$mfd}->{a}, 'tag' => $mfd{$mfd}->{tag} } unless $fh;
        $failed = $mfailed && $afailed;
        $mf = $mfd if ($mfailed && $afailed);
        $apb |= $afailed;
        $mpb |= $mfailed;
        $mfailed = $afailed = undef;
    }

    if ($failed) {
        return 1 if $DoDomainCheck >= 2;
        $this->{prepend}="[MissingMXA]";
        mlog($fh,"MX and A record missing ( DoDomainCheck ) at least for: $mf ($mfd{$mf}->{tag})")
          if $ValidateSenderLog;
        return 0;
    } else {
        $this->{prepend}='';
        return 1;
    }
}
