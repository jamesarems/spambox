#line 1 "sub main::ClamScanOK_Run"
package main; sub ClamScanOK_Run {
    my ($fh,$bd)=@_;
    d('ClamAV');
    my $av;
    my $errstr;
    my $this = $Con{$fh};
    $fh = 0 if $fh =~ /^\d+$/o;
    $this->{clamscandone} = 1 ;

    if (! $this->{scanfile} && $NoScanRe && $$bd=~/($NoScanReRE)/) {
        mlogRe(($1||$2),'NoScanRe','novirusscan');
        return 1;
    }

    my $mtype = 'message';
    $mtype = "whitelisted message"   if $this->{whitelisted};
    $mtype = "noprocessing message"  if $this->{noprocessing};
    $mtype = "local message"         if $this->{relayok};
    $mtype = "file $this->{scanfile}" if $this->{scanfile};

    my $lb = length($$bd);
    my $timeout = $ClamAVtimeout;
    my ( $code, $virus );

    &sigoffTry(__LINE__);
    eval {
   	local $SIG{ALRM} = sub { die "__alarm__\n" };
     	alarm($timeout) if $timeout;
        $av = File::Scan::ClamAV->new( port => $AvClamdPort );
        if ( $av->ping() ) {
            mlog(0, 'ClamAv Up') if $ScanLog && $AvailAvClamd==0 ;
            $VerFileScanClamAV = $File::Scan::ClamAV::VERSION;
            $AvailAvClamd = 1;
            ( $code, $virus ) = $av->streamscan($$bd);
        } else {
            mlog(0, 'ClamAv Down') if $ScanLog && $AvailAvClamd==1 ;
            $AvailAvClamd = 0;
        }
        $errstr = $av->errstr();
        alarm(0);
    };
    alarm(0);
    if ($@) {
        if ( $@ =~ /__alarm__/o ) {
            mlog( $fh, "ClamAV: streamscan timed out after $timeout secs.", 1 );
        } else {
            mlog( $fh, "ClamAV: streamscan failed: $@", 1 );
        }
        undef $av;
        &sigonTry(__LINE__);
        return 1;
    }
    unless ($AvailAvClamd) {
        &sigonTry(__LINE__);
        return 1;
    }
    undef $av;
    mlog($fh,"ClamAV: scanned $lb bytes in $mtype - $code $virus",1)
        if((!( $virus eq '') || !($code eq 'OK')) && $ScanLog ) || $ScanLog >= 2;
    &sigonTry(__LINE__);
    if($code eq 'OK'){
        return 1;
    } elsif ($SuspiciousVirus && $virus=~/($SuspiciousVirusRE)/i) {
        my $SV = $1;
        if ($this->{scanfile}) {
            mlog($fh,"suspicious virus '$virus' (match '$SV') found in file $this->{scanfile} - no action") if $ScanLog;
            return 1;
        }
        $this->{messagereason}="SuspiciousVirus: $virus '$SV'";
        pbAdd($fh,$this->{ip},calcValence(&weightRe('vsValencePB','SuspiciousVirus',\$SV,$fh),'vsValencePB'),"SuspiciousVirus-ClamAV:$virus",1);
        $this->{prepend}="[VIRUS][scoring]";
        mlog($fh,"'$virus' passing the virus check because of only suspicious virus '$SV'") if $ScanLog;
        return 1;
    } elsif($code eq 'FOUND'){
        $this->{prepend}="[VIRUS]";
        $this->{averror}=$AvError;
        $this->{averror}=~s/\$infection/$virus/gio;

        #mlog($fh,"virus detected '$virus'");
        my $reportheader;
        if ($EmailVirusReportsHeader) {
            if ($this->{header} =~ /^($HeaderRe+)/o) {
                $reportheader = "Full Header:\r\n$1\r\n";
            }
            $reportheader ||= "Full Header:\r\n$this->{header}\r\n";
        }
        my $sub="virus detected: '$virus'";

        my $bod="Message ID: $this->{msgtime}\r\n";
        $bod.="Session: $this->{SessionID}\r\n";
        $bod.="Remote IP: $this->{ip}\r\n";
        $bod.="Subject: $this->{subject2}\r\n";
        $bod.="Sender: $this->{mailfrom}\r\n";
        $bod.="Recipients(s): $this->{rcpt}\r\n";
        $bod.="Virus Detected: '$virus'\r\n";
        $reportheader = $bod.$reportheader;

        # Send virus report to administrator if set
        AdminReportMail($sub,\$reportheader,$EmailVirusReportsTo) if $EmailVirusReportsTo && $fh;

        # Send virus report to recipient if set
        $this->{reportaddr} = 'virus';
        ReturnMail($fh,$this->{rcpt},"$base/$ReportFiles{EmailVirusReportsToRCPT}",$sub,\$bod,'') if ($fh && ($EmailVirusReportsToRCPT == 1 || ($EmailVirusReportsToRCPT == 2 && ! $this->{spamfound})));
        delete $this->{reportaddr};

        $Stats{viridetected}++ if $fh && ! $this->{scanfile};
        delayWhiteExpire($fh);
        $this->{messagereason}="virus detected: '$virus'";
        pbAdd($fh,$this->{ip},'vdValencePB',"virus-ClamAV:$virus");

        return 0;
    }
    $VerFileScanClamAV = $errstr;
    $AvailAvClamd = 0;
    mlog(0, "ClamAv Temporary Off : $VerFileScanClamAV") if $ScanLog;
    return 1;
}
