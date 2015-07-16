#line 1 "sub main::syncConfigSend"
package main; sub syncConfigSend {
    my $name = shift;
# ConfigName.sprintf("%.3f",(Time::HiRes::time())).ip|host.cfg
# first line plain var name\r\n  rest Base64 \r\n.\r\n
# varname:=value\r\n
# file start (.+)$
# file eof\s*$
    return 0 if $WorkerNumber < 10000;
    return 0 unless (&syncCanSync() && $enableCFGShare && $CanUseNetSMTP);
    return 0 unless $isShareMaster;
    return 0 if exists $neverShareCFG{$name};
    return 0 unless exists $Config{$name};
    return 0 if $ConfigSync{$name}->{sync_cfg} < 1;
    my $syncserver = $ConfigSync{$name}->{sync_server};
    my ($k,$v);
    my $r = 0;
    while ( ($k,$v) = each %{$syncserver}) {
        next if $v < 1;
        next if $v == 3;
        $r |= $v;
    }
    unless ($r) {return 0;};
    if ($r == 4) {
        while ( ($k,$v) = each %{$syncserver}) {
            $syncserver->{$k} = 2 if $v == 4;
        }
        &syncWriteConfig();
        return 0;
    }
    d("syncConfigSend $name");
    mlog(0,"syncCFG: request to synchronize $name") if $MaintenanceLog;
    my $body = "$name\r\n";
    $body .= MIME::Base64::encode_base64("$name:=" . ${$name},'') . "\r\n";
    $body .= MIME::Base64::encode_base64("# UUID $UUID",'') . "\r\n";
    my $fil;
    for my $idx (0...$#PossibleOptionFiles) {
        my $f = $PossibleOptionFiles[$idx];
        if ($name eq $f->[0] && $Config{$f->[0]} =~ /^ *file: *(.+)/io) {
           my $ffil = $fil = $1;
           $ffil="$base/$ffil" if $ffil!~/^\Q$base\E/io;
           d("sync: $ffil");
           if (defined ${$name.'RE'} && ${$name.'RE'} =~ /$neverMatchRE/o && -s $ffil) {
              mlog(0,"syncCFG: warning - the file '$fil' is not empty, but the running regex for $name is a never matching regex (used for empty files) - the sync request will be ignored, because it seems that the file contains an invalid regex");
              while (my ($k , $v) = each %{$syncserver}) {
                  next if $v < 1;
                  next if $v == 3;
                  if ($v == 4) {
                      $syncserver->{$k} = 2;
                      next;
                  }
                  if ($v == 1) {
                      $syncserver->{$k} = 2;
                      next;
                  }
              }
              return 0;
           }
           my $fbody = &syncGetFile($fil);
           $body .= $fbody;
           if ($fbody && scalar keys %{$FileIncUpdate{"$ffil$name"}}) {
               foreach (keys %{$FileIncUpdate{"$ffil$name"}}) {
                   $body .= &syncGetFile($_);
                   d("sync: include $_");
               }
           }
           last;
        }
    }
    # send to  %{$syncserver}

    my $failed = 1;
    while (my ($MTA , $v) = each %{$syncserver}) {
        my $TLS;
        next if $v < 1;
        next if $v == 3;
        if ($v == 4) {
            $syncserver->{$MTA} = 2;
            next;
        }
        my $smtp;
      eval {
        my $SMTPMOD; my %sslargs;
        my $useSSL = $syncUsesSSL;
        if ($useSSL && ! $CanUseNetSMTPSSL) {
            die "error: syncUsesSSL is set to ON, but the module Net::SMTP::SSL is not installed or enabled.\n";
        }
        my ($mtaIP) = $MTA =~ /^($IPRe)/o;
        if (   ! $useSSL
            && $DoTLS == 2
            && ! exists $localTLSfailed{$MTA}
            && ! matchIP($mtaIP,'noTLSIP',0,1)
           )
        {
            $TLS = 1;
            mlog(0,"syncCFG: will try to use TLS connection to $MTA") if $MaintenanceLog >= 2;
        }
        if ($useSSL) {
            $SMTPMOD = 'Net::SMTP::SSL';
            %sslargs = getSSLParms(0);
            $sslargs{SSL_startHandshake} = 1;
        } else {
            $SMTPMOD = 'Net::SMTP';
        }

        my ($host,$port) = split(/:/o,$MTA);
        $port ||= 25;

        $smtp = $SMTPMOD->new(
            $host,
            Port => $port,
            Hello   => $myName,
            Debug => ($TLS || $useSSL ? $SSLDEBUG : $debug),
            Timeout => (($TLS || $useSSL) ? max($SSLtimeout,10) : 120),   # 120 is the default in Net::SMTP
            sslParms => \%sslargs,
            getLocalAddress('SMTP',$host)
        );
        my $fh = $smtp;
        my $timeout = (int(length($body) / (1024 * 1024)) + 1) * 60; # 1MB/min
        if ( $smtp &&
             do {if ($TLS) {eval{$smtp->starttls();};$localTLSfailed{$MTA} = time if ($@);};1;} &&
             $smtp->command('SPAMBOXSYNCCONFIG ' , ' ' . Digest::MD5::md5_base64($syncCFGPass))->response() == 2 &&
             $smtp->data() &&
             eval {
                 my $blocking = $fh->blocking(0);
                 my $res = NoLoopSyswrite($fh,$body . "\r\n",$timeout);
                 $fh->blocking($blocking);
                 $res;
             } &&
             $smtp->dataend() &&
             $smtp->quit
            )
        {
            mlog(0,"syncCFG: successfully sent config for $name to $MTA") if $MaintenanceLog;
            $syncserver->{$MTA} = 2;
            $failed = 0;
        } else {
            my $text;
            eval{$text = $smtp ? ' - ' . $smtp->message() : " - can't connect to $MTA";};
            mlog(0,"syncCFG: unable to send config for $name to $MTA$text");
            $syncserver->{$MTA} = 1;
        }
      } unless $syncTestMode; # end eval
        if ($@) {
            mlog(0,"syncCFG: error - unable to send config for $name to $MTA - $@");
            $syncserver->{$MTA} = 1;
            $localTLSfailed{$MTA} = 1 if ($TLS);
        }
        if ($syncTestMode) {
            mlog(0,"syncCFG: [testmode] successfully sent config for $name to $MTA") if $MaintenanceLog;
            $syncserver->{$MTA} = 2;
            $failed = 0;
        }
    }
    &syncWriteConfig();
    return $failed;
}
