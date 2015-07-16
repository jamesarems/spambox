#line 1 "sub main::FileScanOK_Run"
package main; sub FileScanOK_Run {
    my ($fh,$bd)=@_;
    my $this = $Con{$fh};
    $fh = 0 if $fh =~ /^\d+$/o;
    my $failed;
    my $cmd;
    my $res;
    my $virusname;
    my $lb = length($$bd);
    $this->{filescandone} = 1;

    if (! $this->{scanfile} && $NoScanRe && $$bd=~/($NoScanReRE)/) {
        mlogRe(($1||$2),'NoScanRe','novirusscan');
        return 1;
    }

    my $mtype = 'message';
    $mtype = "whitelisted message"   if $this->{whitelisted};
    $mtype = "noprocessing message"  if $this->{noprocessing};
    $mtype = "local message"         if $this->{relayok};
    $mtype = "file $this->{scanfile}" if $this->{scanfile};

    my $file = $FileScanDir . "/a.$WorkerNumber." . int(rand(100000)) . "$maillogExt";
    mlog($fh,"diagnostic: FileScan will scan file - $file") if $ScanLog == 3;
    my $SF;
    eval {
        open $SF,'>' ,"$file";
        binmode $SF;
        print $SF substr($$bd,0,$lb);
        close $SF;
    };
    my $wait; $wait = $1 if ($FileScanCMD =~ /^\s*NORUN\s*\-\s*(\d+)/io);
    Time::HiRes::sleep($wait / 1000) if $wait;
    $ThreadIdleTime{$WorkerNumber} += $wait / 1000;
    if (-r $file) {
        if ($FileScanCMD !~ /^\s*NORUN/io) {
            my $runfile = $file;
            my $rundir = $FileScanDir;
            my $sep;
            if ( $^O eq "MSWin32" ) {
                $sep = '"';
                $runfile =~ s/\//\\/go;
                $runfile = $sep . $runfile . $sep if $runfile =~ / /o;
                $rundir =~ s/\//\\/go;
                $rundir = $sep . $rundir . $sep if $rundir =~ / /o;
            } else {
                $sep = "'";
                $runfile = $sep . $runfile . $sep if $runfile =~ / /o;
                $rundir = $sep . $rundir . $sep if $rundir =~ / /o;
            }
            &ThreadYield();
            $cmd = "$FileScanCMD 2>&1";
            $cmd =~ s/FILENAME/$runfile/go;
            $cmd =~ s/NUMBER/$WorkerNumber/go;
            $cmd =~ s/FILESCANDIR/$rundir/go;
            $cmd =~ s/\*([a-zA-Z0-9\_\-]+)\*/$sep . $this->{$1} . $sep/oge;
            my $usedAPI = 0;
            if (ref($FileScanCMDbuild_API) eq 'CODE') {
                $usedAPI = 1;
                eval{$FileScanCMDbuild_API->(\$cmd,$this);};
                if ($@) {
                    mlog(0,"error: FileScanCMDbuild_API - eval failed - $@");
                    $usedAPI = undef;
                }
            } elsif ($FileScanCMDbuild_API) {
                mlog(0,"error: the variable FileScanCMDbuild_API is not a CODE reference!");
            }
            d("filescan: running - $cmd");
            if ($cmd && defined($usedAPI)) {
                mlog($fh,"diagnostic: FileScan will run command - $cmd") if $ScanLog == 3;
                &sigoff(__LINE__);
                $res = qx($cmd);
                &sigon(__LINE__);
                &ThreadYield();
            } elsif ($cmd) {
                mlog(0,"warning: FileScanCMDbuild_API - eval failed");
            } else {
                mlog(0,"warning: the command calculated for FileScanCMD was empty after processing all replacements") unless $usedAPI;
            }

            $res =~ s/\r//go;
            $res =~ s/\n/ /go;
            $res =~ s/\t/ /go;
            mlog($fh,"diagnostic: FileScan returned $res") if $ScanLog == 3;

            $failed = 1 if ($FileScanBad && $res =~ /$FileScanBadRE/);
            $failed = 1 if ($FileScanGood && $res !~ /$FileScanGoodRE/);
        }
        eval{unlink($file);};

        my $ok = $failed ? " - $res" : ' - OK';
        mlog($fh,"FileScan: scanned $lb bytes in $mtype$ok",1)
            if(($failed && $ScanLog ) || $ScanLog >= 2);
        return 1 unless $failed;
    } else {
        mlog($fh,"FileScan: is unable find temporary $file - possibly removed by the file system scanner") if $ScanLog >= 2;
        $res = 'unable to find file to scan';
        $failed = 1;
    }

    if($failed) {
        ($virusname) = $res =~ /($FileScanRespReRE)/;

        if($virusname && $SuspiciousVirus && $virusname=~/($SuspiciousVirusRE)/i){
            my $susp = $1;
            if ($this->{scanfile}) {
                mlog($fh,"suspicious virus '$virusname' (match '$susp') found in file $this->{scanfile} - no action") if $ScanLog;
                return 1;
            }
            $this->{messagereason}="SuspiciousVirus: $virusname '$susp'";
            pbAdd($fh,$this->{ip},calcValence(&weightRe('vsValencePB','SuspiciousVirus',\$susp,$fh),'vsValencePB'),"SuspiciousVirus-FileScan:$virusname",1);
            $this->{prepend}="[VIRUS][scoring]";
            mlog($fh,"'$virusname' passing the virus check because of only suspicious virus '$susp'") if $ScanLog;
            return 1;
        }

        $this->{prepend}="[VIRUS]";
        if ($DoFileScan == 2) {
            $this->{prepend}="[VIRUS][monitor]";
            mlog($fh,"message is infected but pass - $res") if $ScanLog;
            $this->{messagereason} = "'FileScan' message is infected but pass - $res" unless $fh;
            return 1;
        }
        $virusname = 'a virus' unless $virusname;
        $this->{averror}=$AvError;
        $this->{averror}=~s/\$infection/$virusname/gio;
        my $reportheader;
        if ($EmailVirusReportsHeader) {
            if ($this->{header} =~ /^($HeaderRe+)/o) {
                $reportheader = "Full Header:\r\n$1\r\n";
            }
            $reportheader ||= "Full Header:\r\n$this->{header}\r\n";
        }
        my $sub="virus detected: 'FileScan'";

        my $bod="Message ID: $this->{msgtime}\r\n";
        $bod.="Session: $this->{SessionID}\r\n";
        $bod.="Remote IP: $this->{ip}\r\n";
        $bod.="Subject: $this->{subject2}\r\n";
        $bod.="Sender: $this->{mailfrom}\r\n";
        $bod.="Recipients(s): $this->{rcpt}\r\n";
        $bod.="Virus Detected: 'FileScan' - $res\r\n";
        $reportheader = $bod.$reportheader;
        
        # Send virus report to administrator if set
        AdminReportMail($sub,\$reportheader,$EmailVirusReportsTo) if $EmailVirusReportsTo && $fh;

        # Send virus report to recipient if set
        $this->{reportaddr} = 'virus';
        ReturnMail($fh,$this->{rcpt},"$base/$ReportFiles{EmailVirusReportsToRCPT}",$sub,\$bod,'') if ($fh && ($EmailVirusReportsToRCPT == 1 || ($EmailVirusReportsToRCPT == 2 && ! $this->{spamfound})));
        delete $this->{reportaddr};

        $Stats{viridetected}++ if $fh && ! $this->{scanfile};
        delayWhiteExpire($fh);
        $this->{messagereason}="virus detected: 'FileScan' - $res";
        pbAdd($fh,$this->{ip},'vdValencePB','virus-FileScan:$res');

        return 0;
    } else {
        mlog($fh,"info: FileScan - message is not infected") if $ScanLog >= 2;
        return 1;
    }
}
