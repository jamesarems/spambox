#line 1 "sub main::BlockReportBody2Q"
package main; sub BlockReportBody2Q {
    my ( $fh, $l ) = @_;
    my $this = $Con{$fh};
    my $host;
    d('BlockReportBody2Q');

    $this->{header} .= $l;
    if ( $l =~ /^\.[\r\n]/o || defined( $this->{bdata} ) && $this->{bdata} <= 0 )
    {
        if ( !$CanUseEMM ) {
            mlog( 0,"info: module Email::MIME is not installed and/or enabled - local blockreport is impossible") if $ReportLog;
            BlockReportForwardRequest($fh,$host);
            stateReset($fh);
            $this->{getline} = \&getline;
            sendque( $this->{friend}, "RSET\r\n" );
            return;
        }

        my $isadmin = (   matchSL( $this->{mailfrom}, 'EmailAdmins' )
                       || matchSL( $this->{mailfrom}, 'BlockReportAdmins' )
                       || lc( $this->{mailfrom} ) eq lc($EmailAdminReportsTo)
                       || lc( $this->{mailfrom} ) eq lc($EmailBlockTo) );

        my $smime = {};
        if (   ($BlockReportRequireSMIME & 1 && ! $isadmin)
            || ($BlockReportRequireSMIME & 2 &&   $isadmin) )
        {
            $smime = checkSMIME(\$this->{header},$this->{mailfrom});
            if ( ! $smime->{verified} || ! $this->{header} ) {
                mlog(0,"info: valid SMIME signature required for BlockReport - skip BlockReport");
                &NoLoopSyswrite($fh,"554 Transaction failed - a valid SMIME signature is required for your request\r\n",0);
                stateReset($fh);
                $this->{getline} = \&getline;
                sendque( $this->{friend}, "RSET\r\n" );
                return;
            }
        }

        my $blpass = $isadmin ? $BlockReportAdminPassword->{lc($this->{mailfrom})} : $BlockReportUserPassword ;
        if (   ($BlockReportRequirePass & 1 && ! $isadmin && $blpass && ! $smime->{verified})
            || ($BlockReportRequirePass & 2 &&   $isadmin && $blpass && ! $smime->{verified}) )
        {
            if ( $this->{header} !~ /(?:^|\n)\s*\Q$blpass\E/ ) {
                mlog(0,"info: valid password required for BlockReport - skip BlockReport");
                &NoLoopSyswrite($fh,"554 Transaction failed - a valid password is required for your request\r\n",0);
                stateReset($fh);
                $this->{getline} = \&getline;
                sendque( $this->{friend}, "RSET\r\n" );
                return;
            }
        }

        my $parm = "$this->{mailfrom}\x00$this->{rcpt}\x00$this->{ip}\x00$this->{cip}\x00$this->{header}";
        &cmdToThread( 'BlockReportFromQ', $parm );
        mlog( 0,"info: queued blocked mail request from $Con{$fh}->{mailfrom}")
          if $ReportLog >= 2 or $MaintenanceLog;

        $Email::MIME::ContentType::STRICT_PARAMS = 0;    # no output about invalid CT
        my $email = Email::MIME->new($this->{header});
        my $sub = $email->header("Subject") || '';    # get the subject of the email
        $sub =~ s/\r?\n//go;

        ($host) = $sub =~ /SPAMBOX\-host\s+(.*)/io;
        $host =~ s/\s//go;

        BlockReportForwardRequest($fh,$host) if ( lc($myName) ne lc($host) );

        stateReset($fh);
        $this->{getline} = \&getline;
        sendque( $this->{friend}, "RSET\r\n" );
    }
}
