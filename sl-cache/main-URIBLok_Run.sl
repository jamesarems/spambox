#line 1 "sub main::URIBLok_Run"
package main; sub URIBLok_Run {
    my ( $fh, $bd, $thisip, $done ) = @_;
    my $this = $Con{$fh};
    my $fhh = $fh;
    $fh = 0 if "$fh" =~ /^\d+$/o;
    d('URIBLok');

    return 1 if $this->{whitelisted} && !$URIBLWL;
    return 1 if $this->{relayok} && !$URIBLLocal;
    return 1 if ($this->{noprocessing} & 1) && !$URIBLNP;
    return 1 if $this->{ispip} && !$URIBLISP && !$this->{cip};

    my $ValidateURIBL = $ValidateURIBL;    # copy the global to local - using local from this point
    if ($this->{overwritedo}) {
        $ValidateURIBL = $this->{overwritedo};   # overwrite requ by Plugin
    }

    $thisip = $this->{cip} if $this->{ispip} && $this->{cip};
    my $URIDomainRe;
    my @URIIPs;

    my $ProtPrefix = <<'EOT';
(?:(?i:[\=\%][46]8|\&\#(?:0?72|104)\;?|h)
(?i:[\=\%][57]4|\&\#(?:0?84|116)\;?|t)
|(?i:[\=\%][46]6|\&\#(?:0?70|102)\;?|f))
(?i:[\=\%][57]4|\&\#(?:0?84|116)\;?|t)
(?i:[\=\%][57]0|\&\#(?:0?80|112)\;?|p)
(?i:[\=\%][57]3|\&\#(?:0?83|115)\;?|s)?
(?:[\=\%]3[aA]|\&\#0?58\;?|\:)
(?:[\=\%]2[fF]|\&\#0?47\;?|\/){2}
EOT
    $ProtPrefix =~ s/\r|\n|\s//g;
    my $UriAt = '(?:\@|[=%]40|\&\#0?64\;?)';
    my $UriIPSectDotRe = '(?:'.$IPSectRe.$UriDot.')';
    my $UriIPRe = $ProtPrefix.'(?:[^\@]*?'.$UriAt.')?(?:(?:'.$UriIPSectDotRe.'{3})'.$IPSectRe.'|'.$IPv6Re.')[^\.\w\@]';

    my $URISubDelimsCharRe = quotemeta('[!$&\'()*+,;=%^`{}|]'); # relaxed to a few other characters
    if ($URIBLcheckDOTinURI) {
        $URIDomainRe = $UriAt.'?(?:\w(?:[\w\-]|'.$UriDot.'|'.$dot.')*(?:'.$UriDot.'|' . $dot . ')('. $TLDSRE .'))[^\.\w\@]';
    } else {
        $URIDomainRe = $UriAt.'?(?:\w(?:\w|'.$UriDot.'|\-)*'.$UriDot.'('. $TLDSRE .'))[^\.\w\@]';
    }

    my $slok = $this->{allLoveURIBLSpam} == 1;
    my ( %domains, $ucnt, $uri, $mycache, $orig_uri, $i, $ip, $tlit, $uribl, $received_uribl, $uribl_result , $last_mycache);
    my ( $lookup_return, @listed_by, @last_listed_by, $last_listed_domain, $uribls_returned, $lcnt, $err , $weightsum, %last_results, %results);
#    my %txtresults;

    $ValidateURIBL = 3
      if ((   $ValidateURIBL == 1
           && $switchSpamLoverToScoring
           && $DoPenaltyMessage
           && ( $slok || $this->{spamlover} & 1))
        or
          (   $ValidateURIBL == 1
           && $switchTestToScoring
           && $DoPenaltyMessage
           && ( $uriblTestMode || $allTestMode ))
        );

    $tlit = &tlit($ValidateURIBL);

    if (   $this->{mailfrom}
        && matchSL( $this->{mailfrom}, 'noURIBL' ) )
    {
        mlog( $fh, "URIBL lookup skipped (noURIBL sender)", 1 )
          if $URIBLLog >= 2;
        return 1;
    }

    my $data = &cleanMIMEBody2UTF8($bd);
    $data =~ s/\=(?:\015?\012|\015)//go;
    $data = decHTMLent($data) if $data;
    if ($data || (ref($bd) ? $$bd : $bd) =~ /^$HeaderRe/io) {
        my $head = &cleanMIMEHeader2UTF8($bd,1);
        $head =~ s/\nto:$HeaderValueRe/\n/gios;
        $head =~ s/received:$HeaderValueRe//gios;
        $head =~ s/Message-ID:$HeaderValueRe//gios;
        $head =~ s/References:$HeaderValueRe//gios;
        $head =~ s/In-Reply-To:$HeaderValueRe//gios;
        $head =~ s/X-Assp-[^:]+?:$HeaderValueRe//gios;
        $head =~ s/bcc:$HeaderValueRe//gios;
        $head =~ s/cc:$HeaderValueRe//gios;
        $head =~ s/[\x0D\x0A]*$/\x0D\x0A\x0D\x0A/o;
        $head = &cleanMIMEHeader2UTF8($head,0);
        headerUnwrap($head);
        $data = $head . $data;
    }
    my ($fdom,$dom);
    my @rcpt = keys %{$this->{rcptlist}};
    my @myNames = ($myName);
    push @myNames , split(/[\|, ]+/o,$myNameAlso);
    my $myName = '(?i:'.join('|', map {my $t = quotemeta($_);$t;} @myNames).'$)';
    my $SKIPURIRE = sub {my $t = shift; my @wuri = map {"$t,$_";} @rcpt; unshift @wuri, $t; return $t =~ /$URIBLWLDRE|$NPDRE|$myName/ || matchRE(\@wuri,'whiteListedDomains',1)};
    ($fdom,$dom) = ($1,$2) if $this->{mailfrom} && $this->{mailfrom} =~ /\@((?:[^\.\s]+\.)*?([^\.\s]+\.[^\.\s]+))$/o ;
    if ($fdom =~ /^$EmailDomainRe$/o) {
        if ($dom && ! localdomains($dom)) {
            mlog($fh,"info: found URI $dom")
                if (($URIBLLog == 2 && ! exists $domains{ lc $dom }) or $URIBLLog == 3);
            $domains{ lc $dom }++;
        }
        if ($fdom && $fdom ne $dom && ! localdomains($fdom)) {
            mlog($fh,"info: found URI $fdom")
                if (($URIBLLog == 2 && ! exists $domains{ lc $fdom }) or $URIBLLog == 3);
            $domains{ lc $fdom }++;
        }
        delete $domains{ lc $dom }  if $SKIPURIRE->($dom);
        delete $domains{ lc $dom }  if $SKIPURIRE->("\@$dom");
        delete $domains{ lc $fdom } if $SKIPURIRE->($fdom);
        delete $domains{ lc $fdom } if $SKIPURIRE->("\@$fdom");
        mlog($fh,"info: registered URI $dom for check") if ($URIBLLog >= 2 && exists $domains{ lc $dom });
        mlog($fh,"info: registered URI $fdom for check") if ($URIBLLog >= 2 && exists $domains{ lc $fdom });
    }

    while ( $data =~ /($URIDomainRe|$UriIPRe)/gi ) {
            $uri = $1;
            d("found raw URI: $uri");
            mlog($fh,"info: found raw URI/URL $uri") if ($URIBLLog == 3);
            $uri =~ s/[^\.\w]$//o if $uri !~ /$UriIPRe/o;
            $uri =~ s/^$ProtPrefix//o;
            $uri =~ s/$UriAt/@/go;
            $uri =~ s/^\@//o;
#            $uri =~ s/\=(?:\015?\012|\015)\.?//go;
            $uri =~ s/(?:$URISubDelimsCharRe|\.)+$//o;
            $uri =~ s/\&(?:nbsp|amp|quot|gt|lt|\#0?1[03]|\#x0[da])\;?.*$//io;
            $uri =~ s/[\=\%]2[ef]|\&\#0?4[67]\;?/./gio;
            $uri =~ s/\.{2,}/\./go;
            $uri =~ s/^\.//o;
            $orig_uri = $uri;

            if ($URIBLcheckDOTinURI) {
                my $ouri = $uri;
                mlog($fh,"replaced URI '$ouri' with '$uri'")
                  if ($uri =~ s/$dot/\./igo && $URIBLLog >= 2);
            }
            $uri =~ s/[%=]([a-f0-9]{2})/&decHTMLentHD($1,'hex')/gieo;                  # decode percents
            $uri =~ s/\&\#(\d+)\;?/&decHTMLentHD($1)/geo;                            # decode &#ddd's
            $uri =~ s/([^\\])?\\(\d{1,3});?/$1.&decHTMLentHD($2,'oct')/geio;           # decode octals
            $uri =~ s/\&\#x([a-f0-9]+)\;?/&decHTMLentHD($1,'hex')/geio;                # decode &#xHHHH's
            # strip redundant dots
            $uri =~ s/\.{2,}/\./go;
            $uri =~ s/^\.//o;
            $uri =~ s/$URISubDelimsCharRe//go;
            $dom = '';
            if ($uri !~ /$IPRe/o) {
                $dom  = $1 if $uri =~ /(?:[^\.]+?\.)?([^\.]+\.[^\.]+)$/o;
                next if $dom && localdomains($dom);
                next if localdomains($uri);
            }
            mlog($fh,"info: found URI $uri")
                if (($URIBLLog == 2 && ! exists $domains{ lc $uri }) or $URIBLLog == 3);

            next if $SKIPURIRE->($uri);
            next if $SKIPURIRE->("\@$uri");

            my $obfuscated = 0;
            if ( $uri =~ /$IPv4Re/o && $uri =~ /^$IPQuadRE$/io ) {
                $i = $ip = undef;
                while ( $i < 10 ) {
                    $ip = ( $ip << 8 ) + oct( ${ ++$i } ) + hex( ${ ++$i } ) + ${ ++$i };
                }
                $uri = inet_ntoa( pack( 'N', $ip ) );
                if ( $URIBLNoObfuscated && $orig_uri !~ /^\Q$uri\E/i ) {
                    $this->{obfuscatedip} = $obfuscated = 1;
                    mlog($fh,"info: URIBL - obfuscated IP found $uri - org IP: $orig_uri") if ($URIBLLog >=2);
                }
                mlog($fh,"info: registered IP-URI $uri for check")
                    if (($URIBLLog == 2 && ! exists $domains{ lc $uri }) or $URIBLLog == 3);
                push @URIIPs , $uri;
            } else {
                if ( $URIBLNoObfuscated && $orig_uri !~ /^\Q$uri\E/i ) {

                    $this->{obfuscateduri} = $obfuscated = 1;
                    mlog($fh,"info: URIBL - obfuscated URI found $uri - org URI: $orig_uri") if ($URIBLLog >=2);
                }
                push @URIIPs , getRRA($uri,'') if $URIBLIPRE !~ /$neverMatchRE/o;;
                if ( $uri =~ /([^\.]+$URIBLCCTLDSRE)$/ ) {
                    $uri = $1;
                    next if $SKIPURIRE->($uri);
                    next if $SKIPURIRE->("\@$uri");
                    push @URIIPs , getRRA($uri,'') if $URIBLIPRE !~ /$neverMatchRE/o;
                    mlog($fh,"info: registered TLD(2/3) URI $uri for check")
                        if (($URIBLLog == 2 && ! exists $domains{ lc $uri }) or $URIBLLog == 3);
                } elsif ($uri =~ /([^\.]+\.$TLDSRE)$/ ) {
                    $uri = $1;
                    next if $SKIPURIRE->($uri);
                    next if $SKIPURIRE->("\@$uri");
                    push @URIIPs , getRRA($uri,'') if $URIBLIPRE !~ /$neverMatchRE/o;
                    mlog($fh,"info: registered TLD URI $uri for check")
                        if (($URIBLLog == 2 && ! exists $domains{ lc $uri }) or $URIBLLog == 3);
                } else {
                    next;
                }
            }

            if ( $URIBLmaxuris && ++$ucnt > $URIBLmaxuris ) {
                $this->{maximumuri} = 1;
            }

            if ( ! $domains{ lc $uri }++ ) {
                $domains{ lc $uri } += $obfuscated * 1000000;
                if ( $URIBLmaxdomains && scalar keys(%domains) > $URIBLmaxdomains ) {
                    $this->{maximumuniqueuri} = 1;
                }
            }
    }
    if (! scalar keys(%domains)) {
        mlog($fh,"no URI's to check found in mail") if ($URIBLLog>=2);
        return URIBLIP($fhh, $thisip, $done, \@URIIPs);
    }
    &ThreadYield();

    $this->{myheader} .= 'X-Assp-Detected-URI: '
                      . join(', ',
                             map{$_ . '('.(($domains{$_} >= 1000000)
                                            ? int($domains{$_}/1000000)
                                            : $domains{$_}).')'}
                             keys %domains) . "\r\n"
                      if $AddURIS2MyHeader;

    &sigoff(__LINE__);
    my $urinew = eval {
        RBL->new(
            reuse       => ($DNSReuseSocket?'RBLobj':undef),
            lists       => [@uribllist],
            server      => \@nameservers,
            max_hits    => $URIBLmaxhits,
            max_replies => $URIBLmaxreplies,
            query_txt   => 0,
            max_time    => $URIBLmaxtime,
            timeout     => $URIBLsocktime,
            tolog       => $URIBLLog>=2 || $DebugSPF
          );
    };
    # add exception check
    if ($@ || ! ref($urinew)) {
        &sigon(__LINE__);
        mlog($fh,"URIBL: error - $@" . ref($urinew) ? '' : " - $urinew");
        return URIBLIP($fhh, $thisip, $done, \@URIIPs);
    };
    &sigon(__LINE__);

    $received_uribl = $uribl_result = $lookup_return = $last_listed_domain = $uribls_returned = $last_mycache = undef;
    @last_listed_by = @listed_by = %last_results = ();

    for my $domain (sort keys %domains ) {
        next if !$domain;
        my $isobfuscated = ($domains{ $domain } > 1000000) ? 2 : 1;
        $mycache = 0;
        my %cachedRes = ();
        my $uriweight = 0;
        @listed_by = ();

        my ( $ct, $status, @clb ) = split(/\s+/o, $URIBLCache{$domain} );
        if ( $status == 2  ) {
            mlog($fh,"URIBLCache: $domain OK") if $URIBLLog > 2;
            next;
        } elsif ( $status == 1 ) {
            mlog($fh,"URIBLCache: $domain listed in '@clb'") if $URIBLLog >= 2;
            foreach my $en (@clb) {
                my ($dom,$res) = split(/\<\-/o,$en);
                next unless $dom;
                push @listed_by, $dom;
                $cachedRes{$dom} = $res;
            }
            $mycache = 1;
        } else {
            &sigoff(__LINE__);
            $lookup_return   = eval{$urinew->lookup( $domain, "URIBL" );};
            @listed_by       = $@ ? '' : eval{$urinew->listed_by();};
#            %txtresults      = $@ ? () : eval{$urinew->txt_hash();};
            &sigon(__LINE__);
            mlog($fh,"URIBL: lookup returned <$lookup_return> for $domain - res: '@listed_by'") if ($URIBLLog == 3 or ($URIBLLog == 2 && $lookup_return && $lookup_return ne 1));
            mlog($fh,"URIBL: lookup failed for $domain - $@") if ($@);
            next if ($@ or $lookup_return ne 1);
        }
        my @lb = @listed_by;
        if (@lb) {
            $last_listed_domain = $domain;
            @last_listed_by = @listed_by;
            %last_results = $mycache ? %cachedRes : %{$urinew->{results}};
            $last_mycache = $mycache;
        }
        $lcnt = 0;
        foreach (@lb) {
            my $blhash = $_;
            mlog(0,"URIBL: DIAG-LB: processing $_ (Cache=$mycache)") if ( $URIBLLog > 2 );
            s/\Q$domain\E\.//g;
            mlog(0,"URIBL: DIAG-LR: processing $_ with $last_results{$blhash}") if ( $URIBLLog > 2 );

            if ($last_results{$blhash} =~ /(127\.\d+\.\d+\.\d+)/o) {
                if ($1 eq '127.0.0.1' && ! exists $URIBLweight{$_}{'127.0.0.1'}) {  # query volume reached or error
                    mlog(0,"URIBL: SP '$_' returned a 'query volume reached - 127.0.0.1' for $domain") if ( $URIBLLog > 1 );
                    next;
                }
                my $w;
                $w = matchHashKey($URIBLweight{$_},$1,"0 1 1") if exists $URIBLweight{$_} && $URIBLweight{$_};
                if ($w) {
                    $uriweight += $w * $isobfuscated;
                    mlog(0,"URIBL: DIAG-F: $domain, listed in $_, reply: $1, weight: $w, current uri score: $uriweight, is obfuscated: ".($isobfuscated-1)) if ( $URIBLLog > 2 );
                } else {
                    mlog(0,"URIBL: DIAG-N: $domain, listed in $_, reply: $1, weight: $w, current uri score: $uriweight, is obfuscated: ".($isobfuscated-1)) if ( $URIBLLog > 2 );
                    next;
                }
            } else {
                if (exists $URIBLweight{$_} && exists $URIBLweight{$_}{'*'} && $URIBLweight{$_}{'*'} ) {
                    my $w = $URIBLweight{$_}{'*'};
                    $uriweight += $w * $isobfuscated;
                    mlog(0,"URIBL: DIAG-F*: $domain, listed in $_, weight: $w, current uri score: $uriweight, is obfuscated: ".($isobfuscated-1)) if ( $URIBLLog > 2 );
                } else {
                    mlog(0,"URIBL: DIAG-N*: $domain, listed in $_, weight: 0, current uri score: $uriweight, is obfuscated: ".($isobfuscated-1)) if ( $URIBLLog > 2 );
                    next;
                }
            }
            $lcnt++;
        }
        $uribls_returned += $lcnt;
        $weightsum += $uriweight;

        if (! $mycache) {
            if ($lcnt == 0) {
                URIBLCacheAdd( $domain, "2" ) if (! @lb);
            } else {
                my $listed;
                foreach (@listed_by) {
                    $listed .= "$_<-" . $last_results{$_} . ' ' ;
                }
                $listed =~ s/\s$//o;
                $listed =~ s/^\s//o;
                $listed =~ s/\Q$domain\E\.//g;
                URIBLCacheAdd( $domain, "1", $listed );
            }
        } elsif ($mycache && $lcnt == 0) {
            lock($URIBLCacheLock) if $lockDatabases;
            delete $URIBLCache{$domain};
        }
        
        last if ( (!$URIBLmaxweight && $uribls_returned >= $URIBLmaxhits)
               or ($URIBLmaxweight && $weightsum >= $URIBLmaxweight));
    }
    
    @listed_by = @last_listed_by;
    %results = %last_results;
    $mycache = $last_mycache;
    my $listed = "@listed_by";
    $listed =~ s/\Q$last_listed_domain\E\.//g;
    $weightsum = $URIBLmaxweight if $URIBLmaxweight && $weightsum > $URIBLmaxweight;

    if ( $uribls_returned > 0) {
        foreach (@listed_by) {
            $received_uribl .= "$_<-" . $results{$_} . "; " ;
        }
        $received_uribl =~ s/\Q$last_listed_domain\E\.//g;
        $listed = $received_uribl if $URIBLLog >= 2;
        $this->{uri_listed_by} = $received_uribl if ($this->{skipuriblPL} || ! $fh);
        $mycache = $mycache ? 'URIBLcache' : 'URIBL' ;
        if ( (!$URIBLmaxweight && $uribls_returned >= $URIBLmaxhits) or ($URIBLmaxweight && $weightsum >= $URIBLmaxweight) ) {
            $this->{messagereason} = "$mycache: fail, $last_listed_domain listed in $listed";
            $this->{prepend} = "[URIBL]";
        } else {
            $this->{messagereason} = "$mycache: neutral, $last_listed_domain listed in $listed";
            mlog( $fh, "$tlit ($this->{messagereason}" )
              if ( $URIBLLog && $ValidateURIBL >= 2 && $fh);
            pbWhiteDelete( $fh, $thisip ) if $fh;
            return URIBLIP($fhh, $thisip, $done, \@URIIPs) if $ValidateURIBL == 2;
            $weightsum = ${'uriblnValencePB'}[0] unless $URIBLmaxweight;
            pbAdd( $fh, $thisip, calcValence($weightsum,'uriblnValencePB'), "URIBLneutral" ) if $fh;
            $this->{myheader} .= "X-Assp-$this->{messagereason}\r\n" if $AddURIBLHeader;
            return URIBLIP($fhh, $thisip, $done, \@URIIPs) ;
        }
    } else {
        return URIBLIP($fhh, $thisip, $done, \@URIIPs);
    }

    mlog( $fh, "$tlit ($this->{messagereason}" )
      if ( $URIBLLog && $ValidateURIBL >= 2 && $fh);
    return URIBLIP($fhh, $thisip, $done, \@URIIPs) if $ValidateURIBL == 2 && $fh;

    pbWhiteDelete( $fh, $thisip ) if $fh;
    $weightsum = ${'uriblValencePB'}[0] if $weightsum < ${'uriblValencePB'}[0] && ! $URIBLmaxweight;
    pbAdd( $fh, $thisip, calcValence($weightsum,'uriblValencePB'), "URIBLfailed" ) if $fh;
    $this->{myheader} .= "X-Assp-$this->{messagereason}\r\n" if $AddURIBLHeader && $fh;
    $this->{uri_listed_by} = $received_uribl if ($this->{skipuriblPL} || ! $fh);
    return URIBLIP($fhh, $thisip, $done, \@URIIPs) if $ValidateURIBL == 3;
    $err = $URIBLError;
    $err =~ s/URIBLNAME/$received_uribl/go;
    my $testmode = $uriblTestMode;
    if ($fh && ! $slok) {$Stats{uriblfails}++;}
    thisIsSpam($fh,$this->{messagereason},$URIBLFailLog,$err,$uriblTestMode,$slok,$done) if ($fh && ! $this->{skipuriblPL});  # do not thisisspam if called from Plugin routines
    return 0;
}
