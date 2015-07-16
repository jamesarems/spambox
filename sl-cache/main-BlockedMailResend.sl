#line 1 "sub main::BlockedMailResend"
package main; sub BlockedMailResend {
    my ( $fh, $filename , $special) = @_;
    my $this = $Con{$fh};
    my $infile;
    my $outfile;
    my $sender;
    d("BlockedMailResend - $filename");

    return unless ($resendmail);
    return unless ($CanUseEMS);

    $special =~ s/[(\[][^(\[)\]]*[)\]]//io;
    my ($resfile) = $filename =~ /([^\\\/]+\Q$maillogExt\E)$/i;
    my $fname = $resfile;
    my $corrNotSpamFile = "$base/$correctednotspam/$resfile";
    $resfile = "$base/$resendmail/$resfile";
    if ( $filename !~ /[\\\/]+\Q$spamlog\E[\\\/]+/ ) {
        $corrNotSpamFile = '';
    }
    unless ($open->($outfile,'>' ,$resfile)) {
        mlog( 0, "error: unable to open output file ".de8($resfile)." - $!" ) if $ReportLog;
        return;
    }
    my $foundDir;
    if (!($open->($infile,'<',$filename)) && !$doMove2Num) {    # if the original file is not found, try to find it anywhere
        foreach ($spamlog,$discarded,$notspamlog,$incomingOkMail,$viruslog,$correctedspam,$correctednotspam,
                 "rebuild_error/$spamlog","rebuild_error/$notspamlog","rebuild_error/$correctedspam","rebuild_error/$correctednotspam") {
            next unless $_;
            ($open->($infile,'<',"$base/$_/$fname")) and ($foundDir = $_) and last;
        }
    }
    unless ( $infile->fileno ) {
        mlog( 0, "error: can't open requested file ".de8($fname)." in any collection folder" ) if $ReportLog;
        local $/ = "\r\n";
        $filename =~ s/^.*?\/?([^\/]*\/?[^\/]+)$/$1/o;
        $outfile->print( <<EOT );
From: $EmailFrom
To: $this->{mailfrom}
Subject: failed - request SPAMBOX to resend blocked mail

The requested email-file $filename no longer exists on SPAMBOX-host $myName.
Please contact your email administrator, if you need more information.

.
EOT
        $outfile->close;
        undef local $/;
        $nextResendMail =
          $nextResendMail < time + 3 ? $nextResendMail : time + 3;
        return;
    }

    my $foundRecpt;
    my $requester;
    $foundRecpt = 1
      if ( matchSL( $this->{mailfrom}, 'EmailAdmins', 1 )
        or matchSL( $this->{mailfrom}, 'BlockReportAdmins', 1 )
        or lc( $this->{mailfrom} ) eq lc($EmailAdminReportsTo)
        or lc( $this->{mailfrom} ) eq lc($EmailBlockTo)
        or ($requester = matchSL( $this->{mailfrom}, 'EmailResendRequester', 1 ))
        );

    $foundDir = $viruslog if (! $foundDir && $viruslog && $filename =~ /^\Q$base\E\/\Q$viruslog\E\//);
    if (!$foundRecpt && $viruslog && $foundDir eq $viruslog) {
        mlog( 0, "warning: resend for file $filename denied - found it in viruslog folder $viruslog" ) if $ReportLog;
        local $/ = "\r\n";
        $filename =~ s/^.*?\/?([^\/]*\/?[^\/]+)$/$1/o;
        $outfile->print( <<EOT );
From: $EmailFrom
To: $this->{mailfrom}
Subject: denied - request SPAMBOX to resend blocked mail

The requested email-file $filename on SPAMBOX-host $myName possibly contains a virus!
Please contact your email administrator, if you need more information.

.
EOT
        $outfile->close;
        undef local $/;
        $nextResendMail =
          $nextResendMail < time + 3 ? $nextResendMail : time + 3;
        return;
    }
    $outfile->binmode;
    my $header = "X-Assp-Resend-Blocked: $myName\r\n";
    while ( my $line = (<$infile>)) {
        $line =~ s/[\r\n]//og;
        $header .= "$line\r\n";
        last unless $line;
    }
    headerUnwrap($header);
    $infile->close unless defined(*{'yield'});
    my $lastline;
    my $Skip; $Skip = 1 if $foundRecpt;
    mlog(0,"info: resend: modifying mail header for $fname") if $ReportLog > 1;
    my @requester;
    for my $line (split(/\r\n/o,$header)) {
        my $text;
        my $adr;
        $line =~ s/\r|\n//o;
        next if !$Skip && $line =~ /X-Assp-Intended-For:/io;
        if ( $line =~ /^(to|b?cc|from|X-Assp-(?:Intended-For|Envelope-From)):.*?($EmailAdrRe\@$EmailDomainRe)/oi ) {
            $text = $1 . ':';
            $adr  = $2;
            my @adr = $line =~ /($EmailAdrRe\@$EmailDomainRe)/go;
            $adr = $this->{mailfrom} if ( $text =~ /^to:/io && matchARRAY( qr/^\Q$this->{mailfrom}\E$/i , \@adr) );
            $sender = lc($adr) if ( $text =~ /^X-Assp-Envelope-From:/io );
            $sender ||= lc($adr) if ( $text =~ /^from:/io );
            next if ((!$Skip || ($Skip && $requester)) && ( $text =~ /^cc:/io or $text =~ /^bcc:/io ) );
            next if ((!$Skip || ($Skip && $requester)) && ( $text =~ /^to:/io
                    && lc($adr) ne lc( $this->{mailfrom} ) ));
            push(@requester, $adr) if ($Skip && $requester && $text =~ /^X-Assp-Intended-For:/io );
            next if ($text =~ /^to:/io && ! &localmail($adr));
            $foundRecpt = 2 if ( $text =~ /^to:/io
                                 && lc($adr) eq lc( $this->{mailfrom} ) );
            $foundRecpt = 2 if ( $text =~ /^to:/io && $Skip && ! $requester);
        }
        if ( $line eq '' ) {
            if ( $foundRecpt < 2 || @requester) {
                my $add = ($foundRecpt) ? '(admin)' : '(from)';
                push(@requester,$this->{mailfrom}) unless @requester;
                for (@requester) {
                    mlog(0,"info: resend: adding $add 'To: <$_>' for $fname") if $ReportLog;
                    $outfile->print( "To: <$_>\r\n");
                }
                $foundRecpt = 2;
            }
        }
        $outfile->print(headerWrap("$line\r\n"));
        $lastline = 1 if ( $line eq '.' );
    }

    if ( ! $foundRecpt ) {
        mlog(0,"info: resend: no recipient found - adding (from) 'To: <$this->{mailfrom}>' for $fname") if $ReportLog;
        $outfile->print( "To: <$this->{mailfrom}>\r\n");
        $foundRecpt = 2;
    }

    unless ($lastline) {
        $outfile->print("\r\n");
        mlog(0,"info: resend: adding body of $fname") if $ReportLog > 1;
        my $count = 0;
        while ( my $line = (<$infile>)) {
            $line =~ s/[\r\n]//og;
            $lastline = 1 if ( $line eq '.' );
            $outfile->print("$line\r\n");
            $count++;
        }
        mlog(0,"info: resend: added $count body lines of $fname") if $ReportLog > 1;
        $outfile->print("\r\n.\r\n") unless $lastline;
    }
    $infile->close;
    $outfile->close;

    if ( $autoAddResendToWhite && $sender && !&localmail($sender)) {
        if (   matchSL( $this->{mailfrom}, 'EmailAdmins', 1 )
            or matchSL( $this->{mailfrom}, 'BlockReportAdmins', 1 )
            or lc( $this->{mailfrom} ) eq lc($EmailAdminReportsTo)
            or lc( $this->{mailfrom} ) eq lc($EmailBlockTo) )
        {
            if ( $autoAddResendToWhite > 1 && $special !~ /(?:don'?t|no)[^,]*?whit/io ) {
                &Whitelist($sender,undef,'add');
                mlog( 0, "info: whitelist addition on resend: $sender" )
                  if $ReportLog;
            }
        } elsif ( $autoAddResendToWhite != 2 && $special !~ /(?:don'?t|no)[^,]*?whit/io ) {
            &Whitelist($sender,$this->{mailfrom},'add');
            mlog( 0, "info: whitelist addition on resend: $sender" )
              if $ReportLog;
        }
    }

    if ( $corrNotSpamFile && $DelResendSpam && $special !~ /(?:don'?t|no)[^,]*?(?:del|rem|move)/io) {
        $filename =~ s/\\/\//go;
        $corrNotSpamFile =~ s/\\/\//go;
        if (   matchSL( $this->{mailfrom}, 'EmailAdmins', 1 )
            or matchSL( $this->{mailfrom}, 'BlockReportAdmins', 1 )
            or lc( $this->{mailfrom} ) eq lc($EmailAdminReportsTo)
            or lc( $this->{mailfrom} ) eq lc($EmailBlockTo) )
        {
            $move->( $filename, $corrNotSpamFile ) and $ReportLog or
            mlog(0,"error: unable to move $filename to $corrNotSpamFile - $!" );
        } else {
            $unlink->($filename) and $ReportLog or
            mlog(0,"error: unable to delete $filename - $!" );
        }
    }
    $nextResendMail = $nextResendMail < time + 3 ? $nextResendMail : time + 3;
}
