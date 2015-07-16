#line 1 "sub main::RBLCacheOK_Run"
package main; sub RBLCacheOK_Run {
    my ($fh,$ip,$skipcip) = @_;
    my $this = $Con{$fh};
    $fh = 0 if $fh =~ /^\d+$/o;
    d('RBLCacheOK');
    $this->{rblcache} = 0;
    if (! $skipcip) {
        $ip = $this->{cip} if $this->{cip};
        return 1 if $this->{rblcachedone} && !$this->{cip};
        $this->{rblcachedone} = 1;
    }

    skipCheck($this,'aa','ro','rw','co') && return 1;
    ! $skipcip && skipCheck($this,'ispcip') && return 1;
    return 1 if ($this->{noprocessing} & 1);
    return 1 if $this->{whitelisted} && !$RBLWL;
    return 1 if $this->{pbwhite} || pbWhiteFind($ip);
    return 1 if matchIP( $ip, 'noRBL', 0, 1 );

    my $slok        = $this->{allLoveRBLSpam} == 1;
    my $ValidateRBL = $ValidateRBL;

    my $tlit = &tlit($ValidateRBL);
    my ( $ct, $mm, $status, @rbl );
    return 1 unless ( ( $ct, $mm, $status, @rbl ) = split( ' ', $RBLCache{$ip} ) );
    $this->{rblcache} = 1;
    $this->{rbldone} = 1;

    return 1 if $status==2;

#    my $rbls_returned = $#rbl + 1;
    my $rbls_returned = 0;
    my ($rbllists,$rblweight, $rblweightn, $rblweighttotal);

    foreach (@rbl) {
        if (!$NODHO && s/(dnsbl\.httpbl\.org)\{([^{}]+)\}\[([\d\.]+)\]/$1/io && exists $rblweight{$_} && $rblweight{$_}) {
            my $dhofact = $3;
            my $w;
            $w = matchHashKey($rblweight{$_},$2,"0 1 1");
            $rblweighttotal += $w / 2 * $dhofact if $w;
            $this->{rblweight}->{'dnsbl.httpbl.org'} = "$2 -> $w" if $w && ! $fh;
            mlog(0,"DNSBLcache: DIAG-NODHO: IP: $ip, listed in: $_, reply: $2, weight: $w, total: $rblweighttotal") if ($RBLLog >= 2);
            next unless $w;
        } elsif (s/([^{}]+)\{([^{}]+?)\}/$1/io && exists $rblweight{$_} && $rblweight{$_}) {
            my $w;
            $w = matchHashKey($rblweight{$_},$2,"0 1 1");
            $rblweighttotal += $w if $w;
            $this->{rblweight}->{$_} = "$2 -> $w" if $w && ! $fh;
            mlog(0,"DNSBLcache: DIAG: IP: $ip, listed in: $_, reply: $2, weight: $w, total: $rblweighttotal") if ($RBLLog >= 2);
            next unless $w;
        } else {
            if (exists $rblweight{$_} && exists $rblweight{$_}{'*'} && $rblweight{$_}{'*'}) {
                my $w = $rblweight{$_}{'*'};
                $rblweighttotal += $w;
                $this->{rblweight}->{$_} = "$2 -> $w" if $w && ! $fh;
                mlog(0,"DNSBLcache: DIAG-*: IP: $ip, listed in: $_, weight: $w, total: $rblweighttotal") if ($RBLLog >= 2);
                next unless $w;
            } else {
                next;
            }
        }
        $rbllists .= "$_, ";
        $rbls_returned++;
    }
    delete $this->{rblweight} if $fh;
    
    if (! $rbls_returned) {
        RBLCacheDelete($ip);
        return 1;
    }

    $rbllists =~ s/, $//o;

    $rblweight = ${'rblValencePB'}[0];
    $rblweightn = ${'rblnValencePB'}[0];
    $rblweight = $rblweightn = $rblweighttotal if $rblweighttotal;
	
    $this->{messagereason} = "$ip listed in DNSBLcache by $rbllists";
    mlog( $fh, "$tlit ($this->{messagereason} at $mm)" )
    					if ($RBLLog >= 2 || $RBLLog && $ValidateRBL >= 2);
    
    return 1 if $ValidateRBL == 2;
 
    
    if ( $rbls_returned >= $RBLmaxhits && ! $rblweighttotal || $rblweighttotal >= $RBLmaxweight) {
        pbWhiteDelete( $fh, $ip ) if $fh;
        $this->{messagereason} = "DNSBLcache: failed, $ip listed in $rbllists";
        pbAdd( $fh, $ip, ($this->{rblweight}->{result} = calcValence($rblweight,'rblValencePB')), "DNSBLfailed" )
          if $ValidateRBL != 2;
    } else {
        pbWhiteDelete( $fh, $ip ) if $fh;
        $this->{messagereason} = "DNSBLcache: neutral, $ip listed in $rbllists";
        mlog( $fh, "[scoring] $this->{messagereason}" )
          if ( $RBLLog && $ValidateRBL == 1 );
        pbAdd( $fh, $ip, ($this->{rblweight}->{result} = calcValence($rblweightn,'rblnValencePB')), "DNSBLneutral" )
          if $ValidateRBL != 2;
        $this->{rblneutral} = 1;
    }
    delete $this->{rblweight} if $fh;
    
    return 1 if $ValidateRBL == 2;
    
    # add to our header; merge later, when client sent own headers
    $this->{myheader} .= "X-Assp-$this->{messagereason}\r\n" if $AddRBLHeader;
 
    return 1 if $ValidateRBL == 3 or $this->{rblneutral} ;
    return 0 unless $fh;
    
    $Stats{rblfails}++ unless $slok && $fh;
    my $reply = $RBLError;
    $this->{prepend} = "[DNSBL]";

    $reply =~ s/RBLLISTED/$rbllists/go;
    if ($ForceRBLCache) {
        thisIsSpam( $fh, "$this->{messagereason}", $RBLFailLog, "$reply", 0, 0, 1 ) if $fh;
    } else {
        thisIsSpam( $fh, "$this->{messagereason}", $RBLFailLog, "$reply", ($rblTestMode || $allTestMode), $slok, ( $slok || $rblTestMode || $allTestMode)) if $fh;
    }
    return 0;
}
