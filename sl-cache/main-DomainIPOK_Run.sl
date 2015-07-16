#line 1 "sub main::DomainIPOK_Run"
package main; sub DomainIPOK_Run {
    my $fh = shift;
    d('DomainIPOK');
    my $this = $Con{$fh};
    my $mfd;
    my $mfdd;
    return 1 if $this->{doneDoDomainIP};
    $this->{doneDoDomainIP} = 1;
    my $myip = $this->{ip};
    if ($this->{ispip} && $this->{cip}) {
        $myip = $this->{cip};
    } elsif ($this->{ispip}) {
        return 1;
    }

    if ($this->{mailfrom} =~ /(\@([^@]+))/o) {
        $mfdd = $1;
        $mfd  = $2;
    } else {
        return 1;
    }
    if (   ! skipCheck($this,'wl','np','co','aa','nb','nd','spfok')
        && (!$maxSMTPdomainIPWL || ($maxSMTPdomainIPWL && $mfd !~ /$IPDWLDRE/))
        && ! matchIP( $myip, 'noPB',            0, 1 )
        && ! matchIP( $myip, 'noProcessingIPs', $fh, 1 )
        && ! matchIP( $myip, 'whiteListedIPs',  $fh, 1 )
        && ! matchIP( $myip, 'noDelay',         $fh, 1 )
        && ! matchIP( $myip, 'acceptAllMail',   0, 1 )
        && ! matchIP( $myip, 'noBlockingIPs',   $fh, 1 )
        &&   pbBlackFind($myip)
        && ! pbWhiteFind($myip)
       )
    {
        $myip=&ipNetwork($myip, $DelayUseNetblocks );
        $myip .= '.' if $DelayUseNetblocks;
        if ((time - $SMTPdomainIPTriesExpiration{$mfd}) > $maxSMTPdomainIPExpiration) {
            $SMTPdomainIPTries{$mfd} = 1;
            $SMTPdomainIPTriesExpiration{$mfd} = time;
            $myip =~ s/\./\\\./go;
            $SMTPdomainIP{$mfd} = $myip;
        } elsif ($myip !~ /^$SMTPdomainIP{$mfd}/) {
            $SMTPdomainIP{$mfd} .= '|' if $SMTPdomainIP{$mfd};
            $myip =~ s/\./\\\./go;
            $SMTPdomainIP{$mfd} .= $myip;
            $SMTPdomainIPTriesExpiration{$mfd} = time if $SMTPdomainIPTries{$mfd}==1;
            $SMTPdomainIPTries{$mfd}++;
        }
        my $tlit = &tlit($DoDomainIP);
        $tlit = '[testmode]'   if $allTestMode && $DoDomainIP == 1 || $DoDomainIP == 4;
        my $DoDomainIP = $DoDomainIP;
        $DoDomainIP = 3 if $allTestMode && $DoDomainIP == 1 || $DoDomainIP == 4;

        if ( $SMTPdomainIPTries{$mfd} > $maxSMTPdomainIP ) {
            $this->{prepend} = "[IPperDomain]";
            $this->{messagereason} = "'$mfdd' passed limit($maxSMTPdomainIP) of ips per domain";

            mlog( $fh, "$tlit $this->{messagereason}")
              if $SessionLog && $SMTPdomainIPTries{$mfd} == $maxSMTPdomainIP + 1;
            mlog( $fh,"$tlit $this->{messagereason}")
              if $SessionLog >= 2 && $SMTPdomainIPTries{$mfd} > $maxSMTPdomainIP + 1;

            pbAdd( $fh, $myip, 'idValencePB', 'LimitingIPDomain' ) if $DoDomainIP != 2;
            if ( $DoDomainIP == 1 ) {
                $Stats{smtpConnDomainIP}++;
                unless (($send250OKISP && $this->{ispip}) || $send250OK) {
                    seterror( $fh, "554 5.7.1 too many different IP's for domain '$mfdd'", 1 );
                    return 0;
                }
            }
        }
    }
    return 1;
}
