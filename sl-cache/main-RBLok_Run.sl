#line 1 "sub main::RBLok_Run"
package main; sub RBLok_Run {
    my ($fh,$ip,$skipcip) = @_;
    my $this = $Con{$fh};
    $fh = 0 if $fh =~ /^\d+$/o;
    $this->{prepend} = '';
    return 1 if $this->{rblcache};
    my $reason;
    my $rblweighttotal;
    if (! $skipcip) {
        $ip = $this->{cip} if $this->{ispip} && $this->{cip};
        return 1 if $this->{rbldone};
        $this->{rbldone} = 1;
    }
    d('RBLok');
    skipCheck($this,'aa','ro','rw','co') && return 1;
    ! $skipcip && skipCheck($this,'ispcip') && return 1;
    return 1 if ($this->{noprocessing} & 1);
    return 1 if $this->{whitelisted} && !$RBLWL;
    return 1 if $this->{pbwhite} || pbWhiteFind($ip);
    return 1 if matchIP( $ip, 'noRBL', 0, 1 );

    my ( $ct, $mm, $status, @rbl ) = split( ' ', $RBLCache{$ip} );
    return 1 if $status==2;

    my $slok = $this->{allLoveRBLSpam} == 1;
    my $ValidateRBL = $ValidateRBL;
    $this->{spamlover} = $slok = 0 if allSH( $this->{rcpt}, 'rblSpamHaters' );
    $ValidateRBL = 3
      if $ValidateRBL==1 && $switchSpamLoverToScoring
          && $DoPenaltyMessage
          && ( $slok || $this->{spamlover} & 1 );
    $ValidateRBL = 3
      if $ValidateRBL==1 && $switchTestToScoring && $DoPenaltyMessage && ($rblTestMode || $allTestMode);
    my $tlit = &tlit($ValidateRBL);

    &sigoff(__LINE__);
    my $rbl = eval {
        RBL->new(
            reuse       => ($DNSReuseSocket?'RBLobj':undef),
            lists       => [@rbllist],
            server      => \@nameservers,
            max_hits    => $RBLmaxhits,
            max_replies => $RBLmaxreplies,
            query_txt   => 0,
            max_time    => $RBLmaxtime,
            timeout     => $RBLsocktime,
            tolog       => $RBLLog>=2 || $DebugSPF
        );
    };

    # add exception check
    if ($@ || ! ref($rbl)) {
        &sigon(__LINE__);
        mlog($fh,"RBLok: error - $@" . ref($rbl) ? '' : " - $rbl");
        return 1;
    }

    my ( $received_rbl, $rbl_result, $lookup_return );
    $lookup_return = eval{$rbl->lookup( $ip, "RBL" );};
    &sigon(__LINE__);
    mlog($fh,"error: RBL check failed : $lookup_return") if ($lookup_return && $lookup_return ne 1);
    mlog($fh,"error: RBL lookup failed : $@") if ($@);
    return 1 if ($lookup_return ne 1);

    my @listed_by = eval{$rbl->listed_by();};
#    my %txtresults = eval{$rbl->txt_hash();};
    my $rbls_returned = $#listed_by + 1;
    if ( $rbls_returned > 0 ) {
        my $ok = '';
        my $dhores;
        my $dhofact;
        foreach (@listed_by) {
            if ($_ =~ /dnsbl\.httpbl\.org/io && $rbl->{results}->{$_} =~ /127\.(\d+)\.(\d+)\.(\d+)/o) {
                my $daysact = $1;
                my $score  = $2;
                my $rscore = 1 + (($score-$daysact)/100) ;
                $rscore = 1 if $score < 1;
                my $htype = $3;
                my %search_engines = (
                                '0' => 'Undocumented',
                                '1' => 'Alta Vista',
                                '2' => 'Ask',
                                '3' => 'Baidu',
                                '4' => 'Excite',
                                '5' => 'Google',
                                '6' => 'Looksmart',
                                '7' => 'Lycos',
                                '8' => 'MSN',
                                '9' => 'Yahoo',
                               '10' => 'InfoSeek',
                               '11' => 'Miscellaneous'
                );
                $dhofact = $htype * $rscore;
                my $w;
                $w = matchHashKey($rblweight{$_},$rbl->{results}->{$_},"0 1 1") if exists $rblweight{$_} && $rblweight{$_};
                if ($htype && $w) {
                    my $pbval = $w / 2 * $dhofact;
                    $rblweighttotal += $pbval;
                    $this->{rblweight}->{'dnsbl.httpbl.org'} = $pbval unless $fh;
                    mlog($fh,"DNSBL: dnsbl.httpbl.org reported: hosttype=$htype, score=$score(scoreweight $rscore), lastact=$daysact, PBval=$pbval") if ($RBLLog >= 2 || $RBLLog && $ValidateRBL >= 2 );
                    $ok = '';
                }
                $ok = $search_engines{$score} if (! $htype && $rbls_returned == 1);
                $dhores = $rbl->{results}->{$_};
            } elsif ($rbl->{results}->{$_} =~ /(127\.\d+\.\d+\.\d+)/o) {
                if ($1 eq '127.0.0.1' && ! exists $rblweight{$_}{'127.0.0.1'}) {
                    mlog(0,"DNSBL: SP '$_' returned a 'query volume reached - 127.0.0.1' for IP $ip") if ( $RBLLog > 1 );
                    $rbls_returned--;
                    next;
                }
                my $w;
                $w = matchHashKey($rblweight{$_},$1,"0 1 1") if exists $rblweight{$_} && $rblweight{$_};
                if ($w) {
                    $rblweighttotal += $w;
                    $this->{rblweight}->{$_} = "$1 -> $w" unless $fh;
                    mlog(0,"DNSBL: DIAG: IP: $ip, listed in: $_, reply: $1, weight: $w, total: $rblweighttotal") if ($RBLLog >= 2);
                    $ok = '';
                } else {
                    $rbls_returned--;
                    mlog($fh,"DNSBL: result '$1' from '$_' was ignored for $ip") if ($RBLLog >= 2 || $RBLLog && $ValidateRBL >= 2 );
                }
            } else {
                if (exists $rblweight{$_} && exists $rblweight{$_}{'*'} && $rblweight{$_}{'*'}) {
                    my $w = $rblweight{$_}{'*'};
                    $rblweighttotal += $w;
                    $this->{rblweight}->{$_} = "* -> $w" unless $fh;
                    mlog(0,"DNSBL: DIAG-*: IP: $ip, listed in: $_, weight: $w, total: $rblweighttotal") if ($RBLLog >= 2);
                    $ok = '';
                } else {
                    $rbls_returned--;
                    mlog($fh,"DNSBL: hit from '$_' was ignored for $ip") if ($RBLLog >= 2 || $RBLLog && $ValidateRBL >= 2 );
                }
            }
        }
        delete $this->{rblweight} if $fh;
        
        if ($ok) {
            mlog($fh, "DNSBL: pass - $ok - search engine reported by dnsbl.httpbl.org ($dhores)") if ($RBLLog >= 2 || $RBLLog && $ValidateRBL >= 2 );
            RBLCacheAdd( $ip,  "2") if $RBLCacheExp > 0;
            return 1;
        }

        my $rblweight = ${'rblValencePB'}[0];
        my $rblweightn = ${'rblnValencePB'}[0];
        $rblweight = $rblweightn = int($rblweighttotal) if $rblweighttotal;

        $reason = $this->{messagereason} = '';

        if ( $rbls_returned >= $RBLmaxhits && !$rblweighttotal || $rblweighttotal >= $RBLmaxweight) {
            pbWhiteDelete( $fh, $ip ) if $fh;
            $this->{messagereason} = "DNSBL: failed, $ip listed in @listed_by";
            pbAdd( $fh, $ip, ($this->{rblweight}->{result} = calcValence($rblweight,'rblValencePB')), "DNSBLfailed" )
              if $ValidateRBL != 2;
            $received_rbl = "DNSBL: failed, $ip listed in (";
        } elsif ($rbls_returned > 0) {
            pbWhiteDelete( $fh, $ip ) if $fh;
            $this->{messagereason} = "DNSBL: neutral, $ip listed in @listed_by";
            $this->{prepend}       = "[DNSBL]";
            mlog( $fh, "[scoring] DNSBL: neutral, $ip listed in @listed_by" )
              if ( $RBLLog && $ValidateRBL == 1 );
            pbAdd( $fh, $ip, ($this->{rblweight}->{result} = calcValence($rblweightn,'rblnValencePB')), "DNSBLneutral" )
              if $ValidateRBL != 2;
            $this->{rblneutral} = 1;
            $received_rbl = "DNSBL: neutral, $ip listed in (";
        } else {
            RBLCacheAdd( $ip,  "2") if $RBLCacheExp > 0;
            return 1;
        }
        delete $this->{rblweight} if $fh;
        my @temp = @listed_by;
        foreach (@temp) {
            $received_rbl .= "$_<-" . $rbl->{results}->{$_} . "; ";
            $_ .= '{' . $rbl->{results}->{$_} . '}';
            $_ .= "[$dhofact]" if ($_ =~ /dnsbl\.httpbl\.org/io);
        }
        $received_rbl .= ")";
        RBLCacheAdd( $ip,  "1", "@temp" ) if $RBLCacheExp > 0;
    } else {
        RBLCacheAdd( $ip,  "2") if $RBLCacheExp > 0;
        return 1;
    }
    mlog( $fh, "$tlit ($received_rbl)" ) if $received_rbl ne "DNSBL: pass" && ($RBLLog >= 2 || $RBLLog && $ValidateRBL >= 2 );

    return 1 if $ValidateRBL == 2;

    # add to our header; merge later, when client sent own headers
    $this->{myheader} .= "X-Assp-$received_rbl\r\n"
      if $AddRBLHeader && $received_rbl ne "DNSBL: pass";

    if ( $rbls_returned >= $RBLmaxhits && !$rblweighttotal || $rblweighttotal >= $RBLmaxweight) {
        my $slok = $this->{allLoveRBLSpam} == 1;

        return 1 if $ValidateRBL == 3;
        return 0 unless $fh;
        $Stats{rblfails}++;
        my $reply = $RBLError;
        $reply =~ s/RBLLISTED/@listed_by/go;
        $this->{prepend} = '[DNSBL]';
        thisIsSpam( $fh, "DNSBL, $ip listed in @listed_by",
            $RBLFailLog, "$reply", ($rblTestMode || $allTestMode), $slok, ( $slok || $rblTestMode || $allTestMode) ) if $fh;
        return 0;
    }
    return 1;
}
