#line 1 "sub main::SPFok_Run"
package main; sub SPFok_Run {
    my $fh = shift;
    d('SPFok');
    my $do1 = $CanUseSPF && $ValidateSPF;
    my $do2 = $CanUseSPF2 && $ValidateSPF && $SPF2;
    $do1 = 0 if $do2;
    return 1 unless $do1 or $do2;
    
    my $this = $Con{$fh};
    $fh = 0 if "$fh" =~ /^\d+$/o;
    return 1 if $this->{SPFokDone};
    $this->{SPFokDone} = 1;
    my $ip = $this->{ip};
    $ip = $this->{cip} if $this->{ispip} && $this->{cip};
    my $helo = $this->{helo};
    $helo = $this->{ciphelo} if $this->{ispip} && $this->{ciphelo};
    $this->{prepend} = '';
    my $block;
    my $strict;

    return 1 if $this->{relayok} && !$SPFLocal;
    return 1 if $this->{contentonly};
    return 1 if $this->{ispip} && !$this->{cip};
    return 1 if $this->{whitelisted} && !$SPFWL;
    return 1 if ($this->{noprocessing} & 1) && !$SPFNP;
    return 1 if !$SPFLocal && $ip =~ /$IPprivate/o;

    if ( $noSPFRe &&
        ($this->{mailfrom} =~ /($noSPFReRE)/ ||
         $this->{header} =~ /($noSPFReRE)/ )
       )
    {
        mlogRe( $fh, ($1||$2), 'noSPFRe','nospf' );
        return 1;
    }

    if ( $strictSPFRe && $this->{mailfrom} =~ /($strictSPFReRE)/ )
    {
        mlogRe( $fh, ($1||$2), 'strictSPFRe','strictspf' );
        $strict = 1;

    }
    if ( $blockstrictSPFRe && $this->{mailfrom} =~ /($blockstrictSPFReRE)/ )
    {
        mlogRe( $fh, ($1||$2), 'blockstrictSPFRe','blockspf' );
        $strict = 1;
        $block  = 1;
    }
    my $slok = $this->{allLoveSPFSpam} == 1;

    my $ValidateSPF = $ValidateSPF;
    $this->{testmode} = $allTestMode || $spfTestMode;
    if ( $ValidateSPF == 4 ) {
        $ValidateSPF = 1;
        $this->{testmode} = 1;
    }

    my $tlit = tlit($ValidateSPF);

    my ( $header_comment, $detail);
    my ( $local_exp, $authority_exp,$spf_record, $spf_fail, $received_spf);

    my $mf = lc $this->{mailfrom};
    my $mfd;
    $mfd = $1 if $mf =~ /\@([^@]*)/o;
    if (! $mfd) {
        $mfd = $helo;
        $mf = "postmaster\@$helo" unless $mf;
    }
    if ($mfd =~ /^\[?$IPRe\]?$/o) {
        mlog($fh,"info: skip SPF check - domain $mfd is not a FQDN") if $SPFLog;
        return 1;
    }
    my ( $cachetime, $spf_result, $chelo ) = $this->{invalidSenderDomain} ? (9, 'fail', $helo) : SPFCacheFind($ip,$mfd);
    ( $cachetime, $spf_result, $chelo ) = (undef,undef,undef) if $fh == 0 && exists($this->{SPFlimits}) && ! $this->{invalidSenderDomain}; # force SPFbg to query
    
    my ($usedfallback,$usedoverride);
    if ( !$spf_result ) {
        &sigoff(__LINE__);
        my $query;
        my $ip_overwrite;
        if ($do1) {       # Mail::SPF::Query v1.999001
            d('SPF1');
            eval {
                my $timeout = max($ALARMtimeout,($DNStimeout * ($DNSretry + 1)),5);
                local $SIG{ALRM} =
                  sub { die "spf1_query_timeout after $timeout seconds\n" };    # NB: \n required
                alarm ($timeout);

                $query = Mail::SPF::Query->new(
                    sender     => $mf,
                    ipv4       => $ip,
                    helo       => $helo,
                    myhostname => $myName,
                    sanitize   => 1,
                    guess      => $LocalPolicySPF,      # non-standard feature
                    override   => {"$spfoverride"},     # non-standard feature
                    fallback   => {"$spffallback"},     # non-standard feature
                    debug      => $DebugSPF,
                    debuglog => sub { mlog( $fh, "SPF debuglog: @_", 1, 1 ); }
                );
                ( $spf_result, $local_exp, $header_comment, $spf_record, $detail ) = $query->result();

                alarm 0;
                1;
            } or do {
                alarm 0;

            #exception check
                mlog( $fh, "error: SPFOK(1): $@ - for $mfd (mailfrom:$mf / helo:$helo)", 1, 1 );
                &sigon(__LINE__);
                return 1;
            };   # end do eval $do1
        }      # end if $do1

        if ($do2) {              # Mail::SPF v2
            d('SPF2');
            eval {
                my $timeout = max($ALARMtimeout,($DNStimeout * ($DNSretry + 1)),5);
                local $SIG{ALRM} =
                  sub { die "spf2_query_timeout after $timeout seconds\n" };    # NB: \n required
                alarm ($timeout);
                my %override   = eval "($spfoverride)";
                my %fallback   = eval "($spffallback)";
                my ( $identity, $scope );
                if ($mfd) {
                    $identity = $mf;
                    $scope    = 'mfrom';
                } else {
                    $identity = $helo;
                    $scope    = 'helo';
                }

                my $res = getDNSResolver();

                my $spf_server = Mail::SPF::Server->new(
                    hostname     => $myName,
                    dns_resolver => $res,
                    max_dns_interactive_terms => (exists($this->{max_dns_interactive_terms})
                                                    ? $this->{max_dns_interactive_terms}
                                                    : $SPF_max_dns_interactive_terms),
                    %{$this->{SPFlimits}}
                    );

                my $request = Mail::SPF::Request->new(
                    versions      => [ 1, 2 ],
                    scope         => $scope,
                    identity      => $identity,
                    ip_address    => $ip,
                    helo_identity => $helo
                );

                my $result;
                my $ovr = matchHashKey(\%override,$mfd);
                mlog(0,"SPF: SPFoverride for domain $mfd - $ovr") if $DebugSPF;
                if ($ovr) {
                    $usedoverride = 1;
                    my $version = ($ovr =~ /\s*v\s*=\s*spf1/io) ? 1 : 2;
                    try {
                        my $record = SPF_get_records_from_text($spf_server, $ovr, 'TXT', $version, $scope, $mfd);
                        $spf_server->throw_result('permerror', $request, "SPF override record not valid: \"$ovr\"\n") unless $record;
                        $request->record($record);
                        $record->eval($spf_server, $request);
                    }
                    catch Mail::SPF::Result with {
                        $result = shift;
                    }
                    except {
                        die ("SPF-exception: @_\n");
                    };
                } else {
                    $result = eval { $spf_server->process($request); };
                    my $fb;
                    if ($result && $result->code eq 'none' && ($fb = matchHashKey(\%fallback,$mfd))) {
                        $usedfallback = 1;
                        mlog(0,"SPF: got result 'none' - but found SPFfallback for domain $mfd => $fb") if $DebugSPF;
                        my $version = ($fb =~ /\s*v\s*=\s*spf1/io) ? 1 : 2 ;
                        try {
                            my $record = SPF_get_records_from_text($spf_server, $fb, 'TXT', $version, $scope, $mfd);
                            $spf_server->throw_result('permerror', $request, "SPF fallback record not valid: \"$ovr\"\n") unless $record;
                            $request->record($record);
                            $record->eval($spf_server, $request);
                        }
                        catch Mail::SPF::Result with {
                            $result = shift;
                        }
                        except {
                            die ("SPF-exception: @_\n");
                        };
                    }
                }

                eval { $spf_record = $request->record; };
                if ($result) {

                    $spf_result    = $result->code;  $spf_result =~ s/\\(["'])/$1/go;
                    $local_exp     = $result->local_explanation; $local_exp =~ s/\\(["'])/$1/go;
                    $authority_exp = eval{$result->authority_explanation if $result->can('authority_explanation');}; $authority_exp =~ s/\\(["'])/$1/go;
                    $received_spf = $result->received_spf_header; $received_spf =~ s/\\(["'])/$1/go;
                    $this->{received_spf} = $received_spf unless $fh;    # for analyze only
                } else {
                    $spf_result = 'error';
                }
                
                if (   $enableSPFbackground
                    && $SPFCacheInterval
                    && $SPFCacheObject
                    && ! exists($this->{SPFlimits})
                    && $spf_result eq 'permerror'
                    && $local_exp =~ /Maximum DNS-interactive terms limit/io
                   )
                {
                    cmdToThread('SPFbg',"$ip $mf $helo"); # try without limits in background
                }

                my $spfmatch;   # detect faiked SPF records
                $spfmatch = $1 if $received_spf =~ /(mechanism .+? matched)/io;
                my $minV4Network = min(($spf_record =~ /$IPv4Re\/(\d+)/go), ($spfmatch =~ /$IPv4Re\/(\d+)/go));
                $minV4Network = 24 unless defined $minV4Network;
                $minV4Network *= 4;
                my $minV6Network = min(($spf_record =~ /$IPv6Re\/(\d+)/go), ($spfmatch =~ /$IPv6Re\/(\d+)/go));
                $minV6Network = 96 unless defined $minV6Network;
                my $rec;
                if ($spf_result eq 'pass' &&
                    (  $spf_record =~ /\s*((?:v\s*=\s*spf.|spf2.0\/\S+).*?\+all)/oi #  ...+all  allows all IPs
                    || $spf_record =~ /\s*((?:v\s*=\s*spf.|spf2.0\/\S+).*?\D0+\.0+\.0+\.0+(?:\/\d+\s+)?.*?(?:all)?)/oi  # '0.0.0.0/xxx' allows also all IPs
                    || $spfmatch =~ /(\+all)/io
                    || $spfmatch =~ /\D(0+\.0+\.0+\.0+)/io
                    || ($rec = min($minV4Network,$minV6Network) < 32)
                    )
                   )
                {
                    $rec = $rec ? $spfmatch : $1;
                    (my $what, $spf_result) = ($rec=~/([+? ]all)/io || $rec!~/all/io) ?('SPAMMER',($rec=~/\?all/io)?'softfail':'fail'):('suspiciouse','none');
                    $ip_overwrite = '0.0.0.0';
                    mlog($fh,"SPF: found $what SPF record/mechanism '$rec' for domain $mfd - SPF result is set to '$spf_result'") if $SPFLog;
                    $this->{received_spf} .= "\&nbsp;<span class=negative>found $what record/mechanism '$rec' - switched result to '$spf_result'</span>" unless $fh;    # for analyze only
                }

                if ($DebugSPF) {

                    mlog( $fh, "$tlit spf_result:$spf_result", 1, 1 );
                    mlog( $fh, "identity:$identity",           1, 1 );
                    mlog( $fh, "scope:$scope",                 1, 1 );
                    mlog( $fh, "spf_record:$spf_record",       1, 1 );
                    mlog( $fh, "local_exp:$local_exp",         1, 1 );
                    mlog( $fh, "authority_exp:$authority_exp", 1, 1 ) if $authority_exp;
                    mlog( $fh, "received_spf:$received_spf",   1, 1 );
                }
                alarm 0;
                1;
            } or do {
                alarm 0;
            #exception check
                mlog( $fh, "error: SPFOK(2): $@ - for $mfd (mailfrom:$mf / helo:$helo)", 1, 1 );
                &sigon(__LINE__);
                return 1;
            }; # end do eval $do2
        }    # end if $do2
        
        &sigon(__LINE__);

        SPFCacheAdd( ($ip_overwrite?$ip_overwrite:$ip), $spf_result, $mfd, $helo )
            if (   $SPFCacheInterval > 0
                && $spf_result !~ /error/io
                && $ip !~ /$IPprivate/o
                && ! &matchIP($ip,'acceptAllMail',0,1)
               );
    }

    $this->{spf_result} = $spf_result;
    if (    $spf_result eq 'fail'
        || ($spf_result eq 'softfail' && ($SPFsoftfail || $strict))
        || ($spf_result eq 'neutral' && ($SPFneutral || $strict))
        || ($spf_result eq 'none' && ($SPFnone || $strict))
        || ($SPFqueryerror && $spf_result =~ /error|^unknown/io )
      )
    {
        if ($SPFqueryerror && $spf_result =~ /error|^unknown/io ) {
            $spf_fail = 0;
        } else {
            $spf_fail = 1;
        }
        $this->{spfok} = 0;
        pbWhiteDelete( $fh, $ip );
    } else {
        $spf_fail = 0;
        $this->{spfok} = ($spf_result eq 'pass') ? 1 : 0;
    }

    if (   $fh
        && $this->{spfok}       # clear the IP-PBBOX in case SPF is OK
        && $this->{spf_result} eq 'pass')
    {
        $this->{nopb} = 1;
        mlog($fh,"info: remove IP-score from $this->{ip} - this mail passed the SPF check") if ($SessionLog || $SPFLog) && exists $PBBlack{$this->{ip}};
        mlog($fh,"info: remove IP-score from $this->{cip} - this mail passed the SPF check") if ($SessionLog || $SPFLog) && $this->{cip} && exists $PBBlack{$this->{cip}};
        pbBlackDelete($fh, $this->{ip});
    }

    $received_spf = "SPF: $spf_result";
    $received_spf .= " (cache)" if $cachetime;
    $received_spf .= " ip=$ip";
    $received_spf .= " mailfrom=$mf" if ( $mf );
    $received_spf .= " helo=$helo" if ( $helo );
    $this->{received_spf} = $received_spf if (! $fh && ! $this->{received_spf}); # for analyze only
    $this->{received_spf} .= ' (strict)' if (! $fh && $strict);
    $this->{received_spf} .= ' (SFPoverride used)' if (! $fh && $usedoverride);
    $this->{received_spf} .= ' (SPFfallback used)' if (! $fh && $usedfallback);

    mlog( $fh, "$tlit $received_spf", 0, 1 )
      if (($SPFLog && $ValidateSPF >= 2 && !$this->{spfok}) or $SPFLog >= 2);

    return 1 if $ValidateSPF == 2 || $WorkerNumber == 10000;
	$this->{messagereason} = "SPF $spf_result";
    $this->{myheader} .= "X-Assp-Received-$received_spf\r\n"
      if $AddSPFHeader && !$this->{spfok};

    if ($this->{myheader} =~ s/X-Original-Authentication-Results:($HeaderValueRe)//ois) {
        my $val = $1;
        headerUnwrap($val);
        $val =~ s/\r|\n//go;
        $val =~ s/ spf=\S+//o;
        $val .= " spf=$spf_result";
        $this->{myheader} .= "X-Original-Authentication-Results:$val\r\n";
    } else {
        $this->{myheader} .= "X-Original-Authentication-Results: $myName; spf=$spf_result\r\n";
    }

    if ($spf_fail && $strict) {
        pbAdd( $fh, $ip, 'spfValencePB', "SPF$spf_result-strict" ) if $fh;
    } elsif ( $spf_result eq 'neutral' ) {
        pbAdd( $fh, $ip, 'spfnValencePB', "SPF$spf_result" ) if $fh;
    } elsif ( $spf_result eq 'softfail' ) {
        pbAdd( $fh, $ip, 'spfsValencePB', "SPF$spf_result" ) if $fh;
    } elsif ( $spf_result eq 'pass' ) {
        pbAdd( $fh, $ip, 'spfpValencePB', "SPF$spf_result" ) if $fh;
    } elsif ( $spf_result eq 'none' ) {
        pbAdd( $fh, $ip, 'spfnonValencePB', "SPF$spf_result" ) if $fh;
    } elsif ( $spf_result =~ /^unknown|error/io ) {
        pbAdd( $fh, $ip, 'spfeValencePB', "SPFerror" ) if $fh;
    } elsif ( $spf_fail ) {
        pbAdd( $fh, $ip, 'spfValencePB', "SPF$spf_result" ) if $fh;
    }


    return 1 if $ValidateSPF == 3 && !$block;

    if ( $spf_fail == 1 ) {

        return 0 unless $fh;
        # SPF fail (by our local rules)

        my $reply = $SPFError;
        $reply =~ s/SPFRESULT/$local_exp/go;

        $Stats{spffails}++ unless $slok;

        $this->{prepend} = "[SPF]";
        thisIsSpam( $fh, "SPF $spf_result".($strict?' - strict':''),
            $SPFFailLog, $reply, $this->{testmode}, $slok, 0 );
        return 0;
    }

    return 1;
}
