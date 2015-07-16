#line 1 "sub main::Delayok_Run"
package main; sub Delayok_Run {
    my($fh,$rcpt)=@_;
    my $this=$Con{$fh};
    my $client=$this->{friend};
    $this->{prepend}='';
    d('Delayok');

    if ($this->{delaydone}) {
        $this->{delaydone} ='';
        return 1;
    }
    skipCheck($this,'ro','ispip','co','aa') && return 1;
    return 1 if $Con{$client}->{relayok};
    return 1 if $this->{ip} =~ /$IPprivate/o;

    my $mf=lc $this->{mailfrom};
    my $mfwhite=$mf;
    $mfwhite=~s/[^@]*@//o;
    my $time=$UseLocalTime ? localtime() : gmtime();
    my $tz=$UseLocalTime ? tzStr() : '+0000';
    $time=~s/... (...) +(\d+) (........) (....)/$2 $1 $4 $3/o;
    my $ipnet = &ipNetwork($this->{ip}, 1);
    $ipnet =~ s/\.0$//o;
    my $v = $Griplist{$ipnet};
    if (!$DelayWL && $this->{whitelisted}) {

       # add to our header; merge later, when client sent own headers  (per msg)
        $this->{myheader}.="X-Assp-Delay: not delayed (whitelisted); $time $tz\r\n" if ($DelayAddHeader && $this->{myheader} !~ /not delayed \(whitelisted\)/o);
        return 1;
    }
    if (!$DelayNP && ($this->{noprocessing} & 1)) {

       # add to our header; merge later, when client sent own headers  (per msg)
        $this->{myheader}.="X-Assp-Delay: not delayed (noprocessing); $time $tz\r\n" if ($DelayAddHeader && $this->{myheader} !~ /not delayed \(noprocessing\)/o);
        return 1;
    }
    if ($this->{nodelay}) {

       # add to our header; merge later, when client sent own headers  (per msg)
        $this->{myheader}.="X-Assp-Delay: not delayed ($this->{ip} in noDelay ); $time $tz\r\n" if ($DelayAddHeader && $this->{myheader} !~ /not delayed \([\d\.]+ in noDelay\)/o);
        return 1;
    }
    if ( !$DelayWL && pbWhiteFind($this->{ip})) {
        pbBlackDelete( $fh, $this->{ip} );

       # add to our header; merge later, when client sent own headers  (per msg)
        $this->{myheader}.="X-Assp-Delay: not delayed ($this->{ip} in whitebox (PBWhite)); $time $tz\r\n" if ($DelayAddHeader && $this->{myheader} !~ /not delayed \([\d\.]+ in whitebox/o);
        return 1;
    }

    if ( !$DelayWL && $v && $v< 0.4 && $this->{messagescore} <= 0) {
        mlog( $fh, "not delayed (gripvalue low: $v)", 1 ) if $DelayLog >= 2;
       # add to our header; merge later, when client sent own headers  (per msg)
        $this->{myheader} .="X-Assp-Delay: not delayed (gripvalue low: $v); $time $tz\r\n"
              if ( $DelayAddHeader && $this->{myheader} !~ /not delayed \(grip/o );
        return 1;
    }
    if ( !$DelayWL && ($this->{rwlok} or RWLCacheFind($this->{ip}) % 2)) {

       # add to our header; merge later, when client sent own headers  (per msg)
        $this->{myheader}.="X-Assp-Delay: not delayed ($this->{ip} in RWL); $time $tz\r\n" if ($DelayAddHeader && $this->{myheader} !~ /not delayed \([\d\.]+ in RWL /o);
        return 1;
    }
    if (!$DelaySL && $this->{allLoveDLSpam}==1) {

       # add to our header; merge later, when client sent own headers  (per msg)
        $this->{myheader}.="X-Assp-Delay: not delayed (spamlover); $time $tz\r\n" if ($DelayAddHeader && $this->{myheader} !~ /not delayed \(spamlover\)/o);
        return 1;
    }
    if ($this->{dlslre} & 1) {

      # add to our header; merge later, when client sent own headers  (per rcpt)
        $this->{myheader}.="X-Assp-Delay: not delayed (delay-spamlover); $time $tz\r\n" if ($DelayAddHeader && $this->{myheader} !~ /not delayed \(delay-spamlover\)/o);
        return 1;
    }

    my ( $cachetime, $cresult, $chelo ) = SPFCacheFind($this->{ip},$mfwhite);
    if (! $DelayWL && $cresult eq "pass" && $chelo eq lc $this->{helo} && ! &pbBlackFind($this->{ip}) ) {

      # add to our header; merge later, when client sent own headers  (per rcpt)
        $this->{myheader}.="X-Assp-Delay: not delayed (SPF-Cache-OK); $time $tz\r\n" if ($DelayAddHeader && $this->{myheader} !~ /not delayed \(SPF-Cache-OK\)/o);
        return 1;
    }

    if ($DoOrgWhiting == 1 && ! &pbBlackFind($this->{ip})) {
        my ( $ipcountry, $orgname, $domainname, $blacklistscore, $hostname_matches_ip, $cidr ) = split( /\|/o, SBCacheFind($this->{ip}) ) ;
        if (!$DelayWL && $domainname eq $mfwhite && exists $WhiteOrgList{$domainname}) {
          # add to our header; merge later, when client sent own headers  (per rcpt)
            $this->{myheader}.="X-Assp-Delay: not delayed (White-SenderBase-Cache-OK); $time $tz\r\n" if ($DelayAddHeader && $this->{myheader} !~ /not delayed \(White-SenderBase/o);
            return 1;
        }
    }

    if ($DelayNormalizeVERPs) {

        # strip extension
        $mf=~s/\+.*(?=\@)//o;

        # replace numbers with '#'
        $mf=~s/\b\d+\b(?=.*\@)/#/go;
    }
    my $ip=&ipNetwork($this->{ip}, $DelayUseNetblocks );
    my $hash="$ip $mf ". lc $rcpt;
    my $hosthash = $hash;
    my $onhost;
    if ($DelayWithMyName) {
        $hosthash .= " $myName";       # add $myName to triplet to sign entry as host unique
        $onhost = " on host $myName ";
    }

    # get sender domain
    my $hashwhite="$ip $mfwhite";
    if ($CanUseMD5Keys && $DelayMD5) {
        $hash      = Digest::MD5::md5_hex($hash);
        $hosthash  = Digest::MD5::md5_hex($hosthash);
        $hashwhite = Digest::MD5::md5_hex($hashwhite);
    }
    my $t=time;
    my $delay_result;
    my $DelayWhite_hashwhite = $DelayWhite{$hashwhite};
    my $Delay_hash = $Delay{$hash};
    my $Delay_hosthash = $Delay{$hosthash};
    if (! $DelayWhite_hashwhite) {
        if (! $Delay_hash && ! $Delay_hosthash) {
            mlog($fh,"adding new triplet: ($ip,$mf,". lc $rcpt .")$onhost",1) if $DelayLog>=2;
            $Stats{rcptDelayed}++;
            $Delay{$hosthash}=$t;
            $delay_result=0;
        } else {
            my $interval=$t-$Delay_hosthash;
            my $intervalFormatted=formatTimeInterval($interval);
            if ($interval<$DelayEmbargoTime*60) {
                mlog($fh,"embargoing triplet: ($ip,$mf,". lc $rcpt .")$onhost waited: $intervalFormatted",1) if $DelayLog>=2;
                $Stats{rcptEmbargoed}++;
                $delay_result=0;
            } elsif ($interval<$DelayEmbargoTime*60+$DelayWaitTime*3600) {
                mlog($fh,"accepting triplet: ($ip,$mf,". lc $rcpt .")$onhost waited: $intervalFormatted",1) if $DelayLog>=2;
                delete $Delay{$hash};
                delete $Delay{$hosthash};
                $DelayWhite{$hashwhite}=$t;
                $delay_result=1;

                # add to our header; merge later, when client sent own headers
                $this->{myheader}.="X-Assp-Delay: delayed for $intervalFormatted; $time $tz\r\n" if $DelayAddHeader;
            } else {
                mlog($fh,"late triplet encountered, deleting: ($ip,$mf,". lc $rcpt .")$onhost waited: $intervalFormatted",1) if $DelayLog>=2;
                $Stats{rcptDelayedLate}++;
                $Delay{$hosthash}=$t;
                $delay_result=0;
            }
        }
    } else {
        my $interval=$t-$DelayWhite_hashwhite;
        my $intervalFormatted=formatTimeInterval($interval);
        if ($interval<$DelayExpiryTime*24*3600) {
            mlog($fh,"renewing tuplet: ($ip,$mfwhite) age: ". $intervalFormatted,1) if $DelayLog>=2;
            $DelayWhite{$hashwhite}=$t;

            # multiple rcpt's
            delete $Delay{$hash};
            delete $Delay{$hosthash};
            $delay_result=1;

            # add to our header; merge later, when client sent own headers
            $this->{myheader}.="X-Assp-Delay: not delayed (auto accepted); $time $tz\r\n" if $DelayAddHeader;
        } else {
            mlog($fh,"deleting expired tuplet: ($ip,$mfwhite) age: ". $intervalFormatted,1) if $DelayLog>=2;
            $Stats{rcptDelayedExpired}++;

            delete $DelayWhite{$hashwhite};
            $Delay{$hosthash}=$t;
            $delay_result=0;
        }
    }
    return $delay_result;
}
