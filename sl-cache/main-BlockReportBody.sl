#line 1 "sub main::BlockReportBody"
package main; sub BlockReportBody {
    my ( $fh, $l ) = @_;
    my $this = $Con{$fh};
    my $sub;
    my $host;
    my %resendfile = ();
    my $forcelist;    # $this->{blqueued} is set, if V2 has queued
                      # the report to MaintThread
    my $BlModify;
    d('BlockReportBody');
    if (eval('use BlockReport::modify; BlockReport::modify::modify(); 1;')) {
        mlog(0,"info: BlockReport will call the module BlockReport::modify to make your custom changes") if $ReportLog > 1;
        $BlModify = \&BlockReport::modify::modify;
    } else {
        mlog(0,"info: BlockReport was unable to call the module BlockReport::modify - $@") if $ReportLog > 2;
        $BlModify = sub {return shift;};
    }
    $EmailBlockReportDomain = '@' . $EmailBlockReportDomain
      if $EmailBlockReportDomain !~ /^\@/o;
    eval {
        $this->{header} .= $l unless $this->{blqueued};
        if ( $l =~ /^\.[\r\n]/o
            || defined( $this->{bdata} ) && $this->{bdata} <= 0 )
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
            $Email::MIME::ContentType::STRICT_PARAMS =  0;    # no output about invalid CT
            my $email = Email::MIME->new($this->{header});

            $sub = $email->header("Subject") || '';    # get the subject of the email
            $sub = decodeMimeWords($sub);
            $sub =~ s/\r?\n//go;
            $sub =~ s/\s+/ /go;

            #        mlog(0,"subject: $sub");
            ($host) = $sub =~ /ASSP\-host\s+(.*)/io;
            $host =~ s/\s//go;
            my $rsbm_special = 0;
            #       mlog(0,"host: $host");
            foreach my $part ( $email->parts ) {
                my $cs = attrHeader($part,'Content-Type','charset');
                my $body = $part->body;
                if ($cs) {
                    $cs = Encode::resolve_alias(uc($cs));
                    $body = Encode::decode($cs,$body);
                    $body = decHTMLent($body);
                    $body = e8($body);
                } else {
                    mlog(0,"warning: no valid charset found in MIME part") if $ReportLog > 1;
                }
                #           mlog(0,"BODY:\n$body\n");
                my $preline;
                foreach my $line ( split( /\n/o, $body ) ) {
                    $line =~ s/\r?\n//go;
                    my $restrict;
                    my $requdom;
                    $forcelist = 1
                      if (
                           $isadmin
                        && $line =~ /^\s*(?:\[?$EmailAdrRe|\*)\@(?:$EmailDomainRe\]?|\*)\s*\=\>/o
                      );

                    if (   $isadmin
                        && $line =~ /^\s*(\[?$EmailAdrRe|\*)\@($EmailDomainRe\]?|\*)/o
                        && ($requdom = "$1\@$2")
                        && exists $EmailAdminDomains{lc $this->{mailfrom}}
                        && ($restrict = $EmailAdminDomains{lc $this->{mailfrom}})
                        && $requdom !~ /$restrict/i)
                    {
                        mlog(0,"warning: the EmailAdmin '$this->{mailfrom}' has requested a not allowed BlockReport - $line");
                        unloadNameSpace('BlockReport::modify');
                        return;
                    }

                    if ( ( $line =~ /###/o || $preline ) && $line !~ /###/o )
                    {
                        $preline .= $line;
                        next;
                    }
                    if ($preline) {
                        $line    = $preline . $line;
                        $preline = '';
                    }
                    my ($fname,$special) = $line =~ /###(.*)?###(.*)$/o;
                    if ($fname) {
                        $fname =~ s/\r?\n//go;
                        $fname = "$base/$fname";
                        $special =~ s/\r?\n//go;
                        $special = 0 if $special !~ /^[\s\-]*(?:don'?t|not?)[\s=]*(?:whit|del|rem|move)/io;
                        $special ||= 0;
                        $resendfile{$fname} = $special if ! $resendfile{$fname};
                        next;
                    }
                    if (   ! $rsbm_special
                        &&
                           $line !~ /###/io
                        &&
                           $this->{rcpt} =~ /^RSBM_.+?\Q$maillogExt\E\Q$EmailBlockReportDomain\E\s*$/i
                        &&
                           $line =~ /^[\s\-]*(?:don'?t|not?)[\s=]*(?:whit|del|rem|move)/io
                       )
                    {
                        $rsbm_special = $line;
                    }
                }
            }
            if ( $this->{rcpt} =~
                /^(RSBM)_(.+?)\Q$maillogExt\E\Q$EmailBlockReportDomain\E\s*$/i )
            {
                my $rfile = $2;
                mlog(0,"warning: the recipient address '$this->{rcpt}' was changed to lower case - this is a wrong behavior - assp will be possibly unable to find the requested file on nix systems") if $1 eq 'rsbm' && $ReportLog >= 2;
                $rfile =~ s/x([0-9a-fA-F]{2})X/pack('C',hex($1))/geoi;
                $rfile = "$base/$rfile$maillogExt";
                $resendfile{$rfile} = $rsbm_special;
                $sub .= ' resend ' if $sub !~ /resend/io;
            }
            if ( $sub =~ /\sresend\s/io or scalar( keys %resendfile ) ) {
                foreach my $rfile ( keys %resendfile ) {

#               mlog(0,"info: resend filename - $rfile on host - $host to $this->{mailfrom}");
                    if ( (! $host || ( lc($myName) eq lc($host) )) && $resendmail && $CanUseEMS) {
                        my $sp = $resendfile{$rfile} ? " - special specification: $resendfile{$rfile}" : '';
                        $sp = substr($sp,0,50);
                        mlog( 0,"info: got resend blocked mail request from $this->{mailfrom} for $rfile$sp")
                          if $ReportLog >= 2;
                        &BlockedMailResend( $fh, $rfile , $resendfile{$rfile});
                    }
                }
                mlog( 0,"error: got resend blocked mail request from $this->{mailfrom} without valid filename")
                  if ( !scalar( keys %resendfile ) && $ReportLog );
                if ( ! $forcelist ) {
                    BlockReportForwardRequest($fh,$host) if ( ! $this->{blqueued} && lc($myName) ne lc($host) );
                    stateReset($fh);
                    $this->{getline} = \&getline;
                    sendque( $this->{friend}, "RSET\r\n" );
                    unloadNameSpace('BlockReport::modify');
                    return;
                }
            }

            if ($forcelist) {
                my $body;
                my %lines = ();
                mlog( 0,"info: got blocked mail report for a user list from $this->{mailfrom}")
                  if $ReportLog >= 2;
                foreach my $part ( $email->parts ) {
                    my $mbody;
                    my $mbody = decHTMLent( $part->body );
                    while ( $mbody =~
                        /(.*?)((\[?$EmailAdrRe|\*)\@($EmailDomainRe\]?|\*).*)/go )
                    {
                        my $line = $2;
                        $line =~ s/\r?\n//go;
                        $line =~ s/<[^\>]*>//go;
                        my ( $ad, $bd, $cd, $dd) = split( /\=\>/o, $line );
                        $ad =~ s/\s//go;
                        $bd =~ s/\s//go;
                        $cd =~ s/\s*(\d+).*/$1/o;
                        $dd =~ s/^\s*(.*?)\s*$/$1/o;
                        if ( $ad !~ /^(\[?$EmailAdrRe|\*)\@($EmailDomainRe\]?|\*)$/o ) {
                            mlog( 0,"warning: syntax error in $ad, entry was ignored")
                              if $ReportLog;
                            next;
                        }
                        if ( $bd && $bd !~ /^($EmailAdrRe\@$EmailDomainRe|\*)$/o )
                        {
                            mlog( 0,"warning: syntax error in =>$bd, entry was ignored")
                              if $ReportLog;
                            next;
                        }
                        eval{'a' =~ /$dd/i} if $dd;
                        if ( $@ )
                        {
                            mlog( 0,"warning: syntax error in =>$dd, entry was ignored - regex error $@")
                              if $ReportLog;
                            next;
                        }

                        $ad    = lc $ad;
                        $bd    = lc $bd;
                        ($cd)  = $sub =~ /^\s*(\d+)/o  unless $cd;
                        $cd    = 1 unless $cd;
                        $line = "$ad=>$bd=>$cd=>$dd";
                        $body .= "$line\r\n" if ( !exists $lines{$line} );
                        $lines{$line} = 1;
                    }
                }
                if (%lines) {
                    open( my $tmpfh, '<', \$body );
                    $Con{$tmpfh}->{mailfrom} = $this->{mailfrom};
                    BlockReportGen( '1', $tmpfh );
                    delete $Con{$tmpfh};
                }
                if ( !$this->{blqueued} ) {
                    BlockReportForwardRequest($fh,$host) if lc($myName) ne lc($host);
                    stateReset($fh);
                    $this->{getline} = \&getline;
                    sendque( $this->{friend}, "RSET\r\n" );
                }
                unloadNameSpace('BlockReport::modify');
                return;
            }

            if ( $sub =~ /^\s*[\-|\+]/o or $QueueUserBlockReports > 0 ) {
                &BlockReportStoreUserRequest( $this->{mailfrom}, $sub, $QueueUserBlockReports );
                if ( !$this->{blqueued} ) {
                    BlockReportForwardRequest($fh,$host) if lc($myName) ne lc($host);
                    stateReset($fh);
                    $this->{getline} = \&getline;
                    sendque( $this->{friend}, "RSET\r\n" );
                }
                unloadNameSpace('BlockReport::modify');
                return;
            }

            my ($numdays, $exceptRe) = $sub =~ /^\s*(\d+)\s*(.*)$/o;
            if ($exceptRe) {
                eval{'a' =~ /$exceptRe/i};
                if ($@) {
                    mlog(0,"error: regular expression error in blockreport request - $sub - $@");
                    $exceptRe = '';
                }
            }
            $numdays = 5 unless $numdays;
            my %user;
            &BlockReasonsGet( $fh, $numdays , \%user, $exceptRe);
            my @textreasons;
            my @htmlreasons;

            push( @textreasons, $user{sum}{textparthead} );
            push( @htmlreasons, $user{sum}{htmlparthead} );
            push( @htmlreasons, $user{sum}{htmlhead} );
            foreach  my $ad ( sort keys %user ) {
                next if ( $ad eq 'sum' );
                my $number = scalar @{ $user{$ad}{text} } + $user{$ad}{correct};
                $number = 0 if $number < 0;
                $number = 'no' unless $number;
                push(
                    @textreasons,
                    &BlockReportText('text', $ad, $numdays, $number, $this->{mailfrom})
                  );
                my $userhtml =
                  &BlockReportText( 'html', $ad, $numdays, $number,
                    $this->{mailfrom} );
                push( @htmlreasons,  BlockReportHTMLTextWrap(<<"EOT"));
<table id="report">
 <col /><col /><col />
 <tr>
  <th colspan="3" id="header">
   <img src=cid:1001 alt="powered by ASSP on $myName">
   $userhtml
  </th>
 </tr>
EOT
                while ( @{ $user{$ad}{text} } ) { push( @textreasons, shift @{ $user{$ad}{text} } ); }
                while ( @{ $user{$ad}{html} } ) { push( @htmlreasons, BlockReportHTMLTextWrap(shift @{ $user{$ad}{html} } )); }
            }
            if ( scalar( keys %user ) < 2 ) {
                push( @textreasons,"\nno blocked email found in the last $numdays day(s)\n\n");
                push( @htmlreasons,"\nno blocked email found in the last $numdays day(s)\n\n");
            }
            push( @textreasons, $user{sum}{text} );
            push( @htmlreasons, $user{sum}{html} );

            @textreasons = () if ( $BlockReportFormat == 2 );
            @htmlreasons = () if ( $BlockReportFormat == 1 );

            BlockReportSend(
                $fh,
                $this->{mailfrom},
                $this->{mailfrom},
                &BlockReportText(
                    'sub',    $this->{mailfrom},
                    $numdays, 'n/a',
                    $this->{mailfrom}
                  ),
                $BlModify->($user{sum}{mimehead}
                  . join( '', @textreasons )
                  . join( '', @htmlreasons )
                  . $user{sum}{mimebot})
              ) if ( $EmailBlockReply == 1 || $EmailBlockReply == 3 );

            BlockReportSend(
                $fh,
                $EmailBlockTo,
                $this->{mailfrom},
                &BlockReportText(
                    'sub',    $this->{mailfrom},
                    $numdays, 'n/a',
                    $EmailBlockTo
                  ),
                $BlModify->($user{sum}{mimehead}
                  . join( '', @textreasons )
                  . join( '', @htmlreasons )
                  . $user{sum}{mimebot})
              )
              if ( $EmailBlockTo
                && ( $EmailBlockReply == 2 || $EmailBlockReply == 3 ) );

            if ( !$this->{blqueued} ) {
                BlockReportForwardRequest($fh,$host) if lc($myName) ne lc($host);
                stateReset($fh);
                $this->{getline} = \&getline;
                sendque( $this->{friend}, "RSET\r\n" );
            }
        }
      };    # end eval
      if ($@) {
          mlog( 0,"error: unable to process blockreport - $@") if $ReportLog;
          BlockReportForwardRequest($fh,$host) if ( ! $this->{blqueued} && lc($myName) ne lc($host) );
          stateReset($fh);
          $this->{getline} = \&getline;
          sendque( $this->{friend}, "RSET\r\n" );
          unloadNameSpace('BlockReport::modify');
          return;
      }
      unloadNameSpace('BlockReport::modify');
}
