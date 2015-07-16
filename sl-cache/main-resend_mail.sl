#line 1 "sub main::resend_mail"
package main; sub resend_mail {
  return unless($resendmail);
  return unless($CanUseEMS);
  my @filelist;
  my @list = $unicodeDH->("$base/$resendmail");
  while ( my $file = shift @list) {
      next if $dF->( "$base/$resendmail/$file" );
      next if ($file !~ /\Q$maillogExt\E$/i);
      push(@filelist, "$base/$resendmail/$file");
  }
  return unless(@filelist);
  my $bytes = max( $MaxBytes, $ClamAVBytes, 100000 );
  while ( my $file  = shift @filelist) {
      my $hostCFGname;
      my $message = "\r\n";
      mlog(0,"*x*(re)send - try to open: $file") if $MaintenanceLog >= 2;
      next unless($open->(my $FMAIL,'<',$file));
      while (<$FMAIL>) {
          s/\r?\n//go;
          $message .= "$_\r\n";
      }
      $FMAIL->close;
      $message =~ s/[\r?\n]\.[\r?\n]+$/\r\n/so;

# scan for viruses here
#
      my $fh = time;
      $Con{$fh} = {};
      $Con{$fh}->{scanfile} = de8($file);
      if (   $file !~ /\/n\d+\Q$maillogExt\E$/io &&
          (   ($ClamAVLogScan && $UseAvClamd && $CanUseAvClamd && ! ClamScanOK_Run($fh, bodyWrap(\$message,$bytes)))
           || ($FileLogScan && $DoFileScan && $FileScanCMD && ! FileScanOK_Run($fh, bodyWrap(\$message,$bytes))))) {
          $ResendFile{$file} = 98;
          $message = "# (re)send - $file - is virus infected: $Con{$fh}->{averror}\r\n".$message;
          &resendError($file,\$message);
          delete $Con{$fh};
          next;
      }
      delete $Con{$fh};
###

# check for AUTH honeypot mails - and do not resend, delete them here
#
      if ($message =~ /X-Assp-Spam-Reason: faked AUTH success SPAM collecting/ios) {
          $unlink->($file);
          mlog(0,"*x*(re)send - honeypot (faked AUTH success) file: '$file' is removed - resend is not allowed") if $MaintenanceLog;
          delete $ResendFile{$file};
          next;
      }
###
      my $count = exists $ResendFile{$file} ? "(try $ResendFile{$file}" : "(first time)";
      mlog(0,"*x*(re)send - process: $file $count") if $MaintenanceLog >= 2;
      my ($howF, $mailfrom);
      ($howF, $mailfrom) = ($1,$2)
        if ($message =~ /\n(X-Assp-Envelope-From:)[^\<]*?<?($EmailAdrRe\@$EmailDomainRe)>?\s*\r?\n/sio);
      if (! $mailfrom && $message =~ /\n(from:)($HeaderValueRe)/sio) {
          ($howF, my $value) = ($1,$2);
          ($mailfrom) = $value =~ /($EmailAdrRe\@$EmailDomainRe)/sio;
      }

      if (! $mailfrom) {
          ($howF, $mailfrom) = ($1,$2)
             if ($message =~ s/\n(from:)\s*(ASSP <>)\s*\r?\n/\n/sio);
          if (! $mailfrom) {
              mlog(0,"*x*(re)send - $file - From: and X-Assp-Envelope-From: headertag not found");
              $message = "# (re)send - $file - From: and X-Assp-Envelope-From: headertag not found\r\n".$message;
              &resendError($file,\$message);
              next;
          }
      }
#      if (lc $howF eq lc "X-Assp-Envelope-From:") {
#          my ($frN,$frA);
#          ($frN,$frA) = ($1,lc $2) if $message =~ s/\nfrom:\s*([^\<]*?)\s*<?($EmailAdrRe\@$EmailDomainRe)>?\s*\r?\n/\n/sio;
#          $message =~ s/X-Assp-Envelope-From:[^\<]*?<?($EmailAdrRe\@$EmailDomainRe)>?\s*\r?\n/From: <$1>\r\n/iso;
#          if ($frA && lc $1 eq $frA) {
#              $message =~ s/\nFrom:\s*([^\r]+?)\s*\r/\nFrom: $frN $1\r/sio;
#          }
#      }

      my ($howT, $to);
      ($howT, $to) = ($1,$2)
        if ($message =~ /\n(X-Assp-Intended-For:)[^\<]*?<?($EmailAdrRe\@$EmailDomainRe)>?/sio);
      if (! $to && $message =~ /\n(to:)($HeaderValueRe)/sio) {
          ($howT, my $value) = ($1,$2);
          ($to) = $value =~ /($EmailAdrRe\@$EmailDomainRe)/sio;
      }

      if (! $to) {
          mlog(0,"*x*(re)send - $file - To: and X-Assp-Intended-For: headertag not found - skip file");
          $message = "# (re)send - $file - To: and X-Assp-Intended-For: headertag not found - skip file\r\n".$message;
          &resendError($file,\$message);
          next;
      }
      if (lc $howT eq lc "X-Assp-Intended-For:") {
#          $message =~ s/\nto:[^\<]*?<?$EmailAdrRe\@$EmailDomainRe>?\s*\r?\n/\n/sio;
          $message =~ s/\nto:$HeaderValueRe/\n/sio;
          $message =~ s/X-Assp-Intended-For:[^\<]*?<?($EmailAdrRe\@$EmailDomainRe)>?\s*\r?\n/To: <$1>\r\n/sio;
      }

      my $islocal = localmail($to);
      if ($islocal && $ReplaceRecpt) {
            my ($mf) = $mailfrom =~ /($EmailAdrRe\@$EmailDomainRe)/o;
            my $newadr = RcptReplace($to,$mf,'RecRepRegex');
            if (lc $newadr ne lc $to) {
                $message =~ s/(\nto:[^\<]*?<?)\Q$to\E(>?)/$1$newadr$2/is;
                mlog(0,"*x*(re)send - recipient $to replaced with $newadr");
                $to = $newadr;
            }
      }

      $message =~ s/^\r?\n//o;
      $message =~ s/(?:ReturnReceipt|Return-Receipt-To|Disposition-Notification-To):$HeaderValueRe//gios
            if ($removeDispositionNotification);

      mlog(0,"*x*(re)send - $file - $howF $mailfrom - $howT $to") if $MaintenanceLog >= 2;
      my $host = $smtpDestination;
      $hostCFGname = 'smtpDestination';
      if ($EmailReportDestination &&
          $islocal &&
          (($EmailFrom && $EmailFrom =~ /^\Q$mailfrom\E$/i) || lc $mailfrom eq 'assp <>')
         )
      {
          mlog(0,"*x*(re)send - $file - using EmailReportDestination for local mail - From: $mailfrom - To: $to")
              if $MaintenanceLog >= 2;
          $host = $EmailReportDestination;
          $hostCFGname = 'EmailReportDestination';
      }

      if ($islocal && (my @bccRCPT = $message =~ /\nbcc:($HeaderValueRe)/igso)) {
          foreach my $bcc (@bccRCPT) {
              while ($bcc =~ /($EmailAdrRe\@$EmailDomainRe)/igos) {
                  my $addr = $1;
                  if ($ReplaceRecpt) {
                      my ($mf) = $mailfrom =~ /($EmailAdrRe\@$EmailDomainRe)/o;
                      my $newadr = RcptReplace($bcc,$mf,'RecRepRegex');
                      $newadr = '' if ! localmail($newadr);
                      if (lc $newadr ne lc $addr) {
                          $message =~ s/(\nbcc:(?:$HeaderValueRe)*?)$addr/$1$newadr/is;
                          mlog(0,"*x*(re)send - BCC - recipient $addr replaced with $newadr");
                      }
                  }
              }
          }
          $message =~ s/\nbcc:[\r\n\s]+($HeaderNameRe:)?/\n$1/iogs;
      }

      if (! $islocal && $relayHost) {
          mlog(0,"*x*(re)send - $file - using relayHost for not local mail - From: $mailfrom - To: $to")
              if $MaintenanceLog >= 2;
          $host = $relayHost;
          $hostCFGname = 'relayHost';
          my $t = time;
          $Con{$t} = {};
          $Con{$t}->{relayok} = 1;
          $Con{$t}->{mailfrom} = $mailfrom;
          $Con{$t}->{rcpt} = $to;
          $Con{$t}->{header} = $message;
          if ($DoMSGIDsig) {
              if ($message =~ /(Message-ID\:[\r\n\s]*\<[^\r\n]+\>)/io) {
                  my $msgid = $1;
                  my $tag = MSGIDaddSig($t,$msgid);
                  if ($msgid ne $tag ) {
                      $message =~ s/\Q$msgid\E/$tag/i;
                  }
              }
          }
          if ($genDKIM) {
              $Con{$t}->{header} = $message;
              DKIMgen($t);
              $message = $Con{$t}->{header};
          }
          delete $Con{$t};
      }
      my $localip;
      if ( $islocal && $host eq $smtpDestination && $message =~ /X-Assp-Intended-For-IP: ([^\r\n]+)\r\n/o) {
          $localip = $1;
      }
      if (! $host) {
          mlog(0,"*x*(re)send - $file - no SMTP destination found in config - skip file - From: $mailfrom - To: $to");
          $message = "# (re)send - $file - no SMTP destination found in config - skip file - From: $mailfrom - To: $to\r\n".$message;
          &resendError($file,\$message);
          next;
      }
      my $AVa = 0;
      my $reason;
      foreach my $destinationA (split(/\s*\|\s*/o, $host)) {
          my $useSSL;
          if ($destinationA =~ /^(_*INBOUND_*:)?(\d+)$/o){
              $localip ||= ($CanUseIOSocketINET6 ? '[::1]' : '127.0.0.1');
              $localip = '127.0.0.1' if $localip eq '0.0.0.0';
              $localip = '[::1]' if ($localip eq '::');
              if (exists $crtable{$localip}) {
                  $destinationA=$crtable{$localip};
              } else {
                  $destinationA = $localip .':'.$2;
              }
          }
          if ($destinationA =~ /^SSL:(.+)$/oi) {
              $destinationA = $1;
              $useSSL = ' using SSL';
              if ($useSSL && ! $CanUseNetSMTPSSL) {
                  mlog(0,"*x*SSL:$destinationA require Net::SMTP::SSL and IO::Socket::SSL to be installed and enabled, trying others...") ;
                  next;
              }
          }
          if ($AVa<1) {
              mlog(0,"*x*(re)send $file to host: $destinationA$useSSL ($hostCFGname)") if $MaintenanceLog >= 2;
              my $result;
              eval {
                  my ($host,$port) = $destinationA =~ /($HostRe)(?::($PortRe))?$/io;
                  $port ||= 25;
                  my %auth = ($hostCFGname eq 'relayHost' && $relayAuthUser && $relayAuthPass) ? (username => $relayAuthUser, password => $relayAuthPass) : ();
                  my (%from, %to);
                  %from = ('From' => $mailfrom);
#                  %to = ('To' => $to);
                  my $sender = Email::Send->new({mailer => 'SMTP'});
                  $sender->mailer_args([Host => $host, Port => $port, Hello => $myName, tls => ($DoTLS == 2 && ! exists $localTLSfailed{$destinationA} && ! $useSSL), ssl => ($useSSL?1:0), %auth, %from, %to]);
                  eval{ require Email::Send::SMTP; };
                  *{'Email::Send::SMTP::send'} = \&main::email_send_X;
                  eval{$result = $sender->send($message);};
                  mlog(0,"info: in resend_mail: send-result <$result> , returned: $@") if ($@ && $MaintenanceLog);
                  if ($@ && $DoTLS == 2 && ! $useSSL && $@ =~ /STARTTLS: *50\d/io) {
                      $result = undef;
                      $localTLSfailed{$destinationA} = time;
                      $sender = Email::Send->new({mailer => 'SMTP'});
                      $sender->mailer_args([Host => $host, Port => $port, Hello => $myName, NoTLS => 1, %auth, %from, %to]);
                      $result = eval{$sender->send($message)};
                  } elsif ($@) {
                      die "$@\n";
                  }
              };
              if ($@ || ! $result) {
                  mlog(0,"*x*error: unable to send file $file to $destinationA$useSSL ($hostCFGname) - $@") if ($@ && $MaintenanceLog);
                  $@ =~ s/\r?\n/\r\n/go;
                  $@ =~ s/[\r\n]+$//o;
                  $reason .= "# error: unable to send file $file to $destinationA$useSSL ($hostCFGname) - $@\r\n" if $@;
                  mlog(0,"*x*error: unable to send file $file to $destinationA$useSSL ($hostCFGname)") if ($result && $MaintenanceLog);
                  $result =~ s/\r?\n/\r\n/go;
                  $result =~ s/[\r\n]+$//o;
                  $reason .= "# error: unable to send file $file to $destinationA$useSSL ($hostCFGname)\r\n" if $result;
                  mlog(0,"*x**** send to $destinationA$useSSL ($hostCFGname) didn't work, trying others...") ;
                  $reason .= "# send to $destinationA$useSSL ($hostCFGname) didn't work, trying others\r\n";
              } else {
                  mlog(0,"*x*info: successful sent file $file to $destinationA$useSSL ($hostCFGname)") if $MaintenanceLog;
                  $AVa = 1;
                  mlog(0,"*x*warning: unable to delete $file - $!") unless ($unlink->($file));

                  if ( $autoAddResendToWhite > 1 && $islocal && $mailfrom && lc $mailfrom ne 'assp <>' && !&localmail($mailfrom)) {
                      &Whitelist($mailfrom,$to,'add');
                      mlog( 0, "info: whitelist addition on resend via GUI or copied file: $mailfrom" )
                        if $ReportLog || $MaintenanceLog;
                  }
              }
          }
      }
      $message = $reason . $message;
      &resendError($file,\$message);
  }
  return;
}
