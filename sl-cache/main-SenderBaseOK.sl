#line 1 "sub main::SenderBaseOK"
package main; sub SenderBaseOK {
    my ( $fh, $ip ) = @_;
    d('SenderBaseOK');
    my $this = $Con{$fh};
    $fh = 0 if "$fh" =~ /^\d+$/o;
    return 1 if $this->{SenderBaseOK};
    $this->{SenderBaseOK} = 1;
    skipCheck($this,'sb','aa','wl','ro','ispcip') && return 1;
    return 1 if ($this->{noprocessing} & 1);

    $ip = $this->{cip} if $this->{ispip} && $this->{cip};
    return 1 if $ip =~ /$IPprivate/o;

    my $results;
    my $cache;
    my $skip;
    my $tlit;

    my $mfd;
    $mfd = lc $1 if $this->{mailfrom} =~ /\@([^@]*)/o;

    my $ipcountry;
    my $orgname;
    my $domainname;
    my $hostname;
    my $blacklistscore;
    my $hostname_matches_ip;
    my $fortune1000;
    my $ipbondedsender;
    my $domainrating;
    my $resultip;
    my $ipCIDR;

    if ( (( $ipcountry, $orgname, $domainname, $blacklistscore, $hostname_matches_ip, $ipCIDR, $hostname ) = split( /\|/o, SBCacheFind($ip) )) ) {
        $cache = 1;
        d("SenderBase: finished CACHE");
    } else {
        &sigoff(__LINE__);
        eval {
            my $how = $enableWhois & 1;  # 0 = SB only, 1 = whois only, 2 = SB first, 3 = whois first
            mlog($fh,"info: SenderBase - query using ".($how ? 'Whois' : 'SenderBase')) if $SenderBaseLog > 1;
            eval {$results = SPAMBOX::Senderbase::Query->new(
                Address   => $ip,
                Timeout   => ($DNStimeout * ($DNSretry + 1)) || 10,
                useWhoIs => $how
              )->results;};
            $how = $enableWhois >> 1;    # 0 = all done, 1 = next SB or whois
            die $@ if ! $how && $@;      # die if error and only one thing to do
            if ($how && ! (ref($results) && $results->{ip_country})) {
                $how = $enableWhois == 2 ? 1 : 0;  # do whois or SB
                mlog($fh,"info: SenderBase - query using ".($how ? 'Whois' : 'SenderBase')) if $SenderBaseLog > 1;
                $results = SPAMBOX::Senderbase::Query->new(
                    Address   => $ip,
                    Timeout   => ($DNStimeout * ($DNSretry + 1)) || 10,
                    useWhoIs => $how
                  )->results;
            }
        };
        if ($@) {
            mlog( $fh, "warning: SenderBase: $@", 1 ) if $SenderBaseLog > 2;
            &sigon(__LINE__);
            return 1;
        }
        &sigon(__LINE__);

        if (ref($results)) {
            $blacklistscore = $results->{ip_blacklist_score};
            $hostname_matches_ip = $results->{hostname_matches_ip};
            $orgname        = $results->{org_name};
            $resultip       = $results->{ip};
            $fortune1000    = $results->{org_fortune_1000};
            $domainname     = $results->{domain_name};
            $hostname       = $results->{hostname};
            $domainrating   = $results->{domain_rating};
            $ipbondedsender = $results->{ip_in_bonded_sender};
            $ipcountry      = $results->{ip_country};
            $ipCIDR         = $results->{ip_cidr_range};
            if (! $domainname && $hostname) {
                ($domainname) = $hostname =~ /([^\.]+\.(?:$URIBLCCTLDSRE|$TLDSRE))$/i;
            }
            $hostname ||= [PTRCacheFind($ip)]->[2] || getRRData($ip,'PTR');
            if (! $fh) {
                $this->{sbstatus} = 0;
                $this->{sbdata} = "CN=$ipcountry|ORG=$orgname|DOM=$domainname|BLS=$blacklistscore|HNM=$hostname_matches_ip|CIDR=$ipCIDR|HN=$hostname";
            }
            d("SenderBase: finished DNS");
        } else {
            mlog( $fh, "info: SenderBase: got no results", 1 ) if $SenderBaseLog >= 2;
            return 1;
        }
    }
    $ipcountry = uc $ipcountry;
    my $tempdomain; $tempdomain = "domain:$domainname" if $domainname;
    my $temphost; $temphost = "host:$hostname" if $hostname;
    mlog( $fh, "SenderBase -- used $results->{how} -- country:$ipcountry orgname:$orgname $tempdomain $temphost", 1 )
      if $SenderBaseLog >= 2 && ! $cache;
    mlog( $fh, "SenderBase(Cache) -- country:$ipcountry orgname:$orgname $tempdomain $temphost", 1 )
      if $SenderBaseLog >= 2 && $cache;

   
    if ($DoOrgWhiting) {
        my ($ro,$rd,$rh);
        if (   (($ro) = $orgname =~ /($whiteSenderBaseRE)/)
            || (($rd) = $domainname =~ /($whiteSenderBaseRE)/)
            || (($rh) = $hostname =~ /($whiteSenderBaseRE)/))
        {
            my $wSB = $ro || $rd || $rh;
            my $what = $ro ? 'Organization' :
                       $rd ? 'Domain' : 'Host';
            mlogRe( $fh, $wSB, 'whiteSenderBaseRE',"white$what" );
            d("SenderBase: in DoOrgWhiting");
            $tlit = tlit($DoOrgWhiting);
            SBCacheAdd( $ip, 2, "$ipcountry|$orgname|$domainname|$blacklistscore|$hostname_matches_ip|$ipCIDR|$hostname" );
            d("SenderBase0: finished SBCacheAdd in DoOrgWhiting");
            $this->{sbstatus} = 2 if (! $fh);
            if ($DoOrgWhiting == 1 && ! $rh) {
                $WhiteOrgList{$mfd} = $orgname if lc $mfd ne lc $domainname && $this->{spfok};
                $this->{whitelisted} = 1;
                $this->{passingreason} = "White-Senderbase $what: $wSB";
                pbWhiteAdd( $fh, $ip, "WhiteSenderBase:$wSB" );
            }
            $this->{messagereason} = "White $what '$wSB'";
            $this->{messagereason} .= " in cache " if $cache;
            pbAdd( $fh, $ip, calcValence(&weightRe('sworgValencePB','whiteSenderBase',\$wSB,$fh),'sworgValencePB'), "WhiteSenderBase:$wSB" )
              if $DoOrgWhiting != 2;
            mlog( $fh, "$tlit SenderBase -- $this->{messagereason}", 1 )
              if $SenderBaseLog;
            return 1;
        }
    }

    if ($DoOrgBlocking) {

        $this->{prepend} = "[Organization]";
        $tlit = tlit($DoOrgBlocking);
        my ($ro,$rd,$rh);

        d("SenderBase: in DoOrgBlocking");
        if (!$orgname && !$ipcountry ) {
            SBCacheAdd( $ip, 1, "$ipcountry|$orgname|$domainname|$blacklistscore|$hostname_matches_ip|$ipCIDR|$hostname" );
            d("SenderBase1: finished SBCacheAdd in DoOrgBlocking");
            $this->{sbstatus} = 1 if (! $fh);
            pbWhiteDelete( $fh, $ip );
            $this->{messagereason} = "No CountryCode/Organization";
            pbAdd( $fh, $ip,'sbnValencePB', 'NoCountryNoOrg' );
            mlog( $fh, "[Scoring] SenderBase -- $this->{messagereason}", 1 )
              if $SenderBaseLog >= 2;
            return 1;
        } elsif (   (($ro) = $orgname =~ /($blackSenderBaseRE)/)
                 || (($rd) = $domainname =~ /($blackSenderBaseRE)/)
                 || (($rh) = $hostname =~ /($blackSenderBaseRE)/ ))
        {
            my $bSB = $ro || $rd || $rh;
            my $what = $ro ? 'Organization' :
                       $rd ? 'Domain' : 'Host';
            mlogRe( $fh, $bSB, 'blackSenderBaseRE',"black$what" );
            pbWhiteDelete( $fh, $ip );
            SBCacheAdd( $ip, 1, "$ipcountry|$orgname|$domainname|$blacklistscore|$hostname_matches_ip|$ipCIDR|$hostname" );
            d("SenderBase2: finished SBCacheAdd in DoOrgBlocking");
            $this->{sbstatus} = 1 if (! $fh);
            $this->{messagereason} = "Black $what '$bSB'";
            pbAdd( $fh, $ip, calcValence(&weightRe('sborgValencePB','blackSenderBase',\$bSB,$fh),'sborgValencePB'), "BlackOrg:$bSB" )
                if $DoOrgBlocking != 2;

            mlog( $fh, "$tlit SenderBase -- $this->{messagereason}", 1 )
              if $SenderBaseLog >= 2;
            return 0 if $DoOrgBlocking == 1;
        } else {
            SBCacheAdd( $ip, 0, "$ipcountry|$orgname|$domainname|$blacklistscore|$hostname_matches_ip|$ipCIDR|$hostname" );
            d("SenderBase3: finished SBCacheAdd in DoOrgBlocking");
        }
    } else {
        SBCacheAdd( $ip, 0, "$ipcountry|$orgname|$domainname|$blacklistscore|$hostname_matches_ip|$ipCIDR|$hostname" );
        d("SenderBase4: finished SBCacheAdd in DoOrgBlocking");
    }
    
    return 1 unless $DoCountryBlocking;
    return 1 unless $ipcountry;
    if ($NoCountryCodeRe && $ipcountry =~ /$NoCountryCodeReRE/) {
        d("SenderBase5: match NoCountryCodeRe");
        return 1;
    }
    d("SenderBase: DoCountryBlocking");

    $this->{mycountry} = 0;
    my $matchMyCountry = $MyCountryCodeRe && $ipcountry =~ /$MyCountryCodeReRE/;
    my $matchCountryCode = $CountryCodeRe && $ipcountry =~ /$CountryCodeReRE/;

    if (    $ipcountry =~ /$CountryCodeBlockedReRE/
         || (   $CountryCodeBlockedRe =~ /all/io
             && ! $matchMyCountry
             && ! $matchCountryCode
            )
       )
    {
        $this->{messagereason} = "Blocked IP-Country $ipcountry ($orgname)";
        $this->{prepend} = "[CountryCode]";
        $tlit = tlit($DoCountryBlocking);
        pbAdd( $fh, $ip, calcValence(&weightRe('bccValencePB','CountryCodeBlockedRe',\$ipcountry,$fh),'bccValencePB'), "BlockedCountry:$ipcountry" )
          if $DoCountryBlocking != 2;

        mlog( $fh, "$tlit SenderBase -- $this->{messagereason}", 1 )
          if $DoCountryBlocking == 2 || $DoCountryBlocking == 3;

        return 0 if $DoCountryBlocking == 1;
        return 1;
    }

    return 1 if !$DoSenderBase;
    return 1 if !$CountryCodeRe && !$MyCountryCodeRe;
    return 1 unless $fh;
    $tlit = tlit($DoSenderBase);

    ${'sbhccValencePB'}[0] = 0 - ${'sbhccValencePB'}[0] if ${'sbhccValencePB'}[0] > 0;
    ${'sbhccValencePB'}[1] = 0 - ${'sbhccValencePB'}[1] if ${'sbhccValencePB'}[1] > 0;

    if (   (${'sbhccValencePB'}[0] < 0 || ${'sbhccValencePB'}[1] < 0)    # home country
        && $matchMyCountry )
    {
        $this->{prepend}       = "[CountryCode]";
        $this->{mycountry}     = 1;
        $this->{messagereason} = "Home IP-Country Bonus $ipcountry ($orgname)";
        mlog( $fh, "$tlit SenderBase -- $this->{messagereason}", 1 ) if $SenderBaseLog >= 2;
        pbAdd( $fh, $ip, calcValence(&weightRe('sbhccValencePB','MyCountryCodeRe',\$ipcountry,$fh),'sbhccValencePB'), "HomeCountry:$ipcountry" )
          if $DoSenderBase != 2;
        return 1;
    }
    if (   (${'sbfccValencePB'}[0] || ${'sbfccValencePB'}[1])        # foreign country
        && ! $matchMyCountry
        && ! $matchCountryCode )
    {
        $this->{messagereason} = "Foreign IP-Country $ipcountry ($orgname)";
        pbAdd( $fh, $ip, calcValence(&weightRe('sbfccValencePB','CountryCodeRe',\$ipcountry,$fh),'sbfccValencePB'), "CountryCode:$ipcountry", 1 )
          if $DoSenderBase != 2;
        $this->{prepend} = "[CountryCode]";
        mlog( $fh, "$tlit SenderBase -- $this->{messagereason}", 1 ) if $SenderBaseLog >= 2;
        return 1;
    }
    if (
           (${'sbsccValencePB'}[0] || ${'sbsccValencePB'}[1])
        && $matchCountryCode
      )
    {
        $this->{messagereason} = "Suspicious IP-Country $ipcountry ($orgname)";
        pbAdd( $fh, $ip, calcValence(&weightRe('sbsccValencePB','CountryCodeRe',\$ipcountry,$fh),'sbsccValencePB'), "CountryCode:$ipcountry", 1 )
          if $DoSenderBase != 2;
        $this->{prepend} = "[CountryCode]";
        mlog( $fh, "$tlit SenderBase -- $this->{messagereason}", 1 ) if $SenderBaseLog;
        return 1;
    }
    if (   (${'sbfccValencePB'}[0] || ${'sbfccValencePB'}[1])    # Foreign & Suspicious Country
        && $ScoreForeignCountries
        && ! $matchMyCountry
        && $matchCountryCode )
    {
        $this->{messagereason} = "Foreign & Suspicious IP-Country $ipcountry ($orgname)";
        pbAdd( $fh, $ip, calcValence(&weightRe('sbfccValencePB','CountryCodeRe',\$ipcountry,$fh),'sbfccValencePB'), "CountryCode:$ipcountry", 1 )
          if $DoSenderBase != 2;
        $this->{prepend} = "[CountryCode]";
        mlog( $fh, "$tlit SenderBase -- $this->{messagereason}", 1 ) if $SenderBaseLog;
        return 1;
    }
    return 1;
}
