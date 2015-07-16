#line 1 "sub main::mlog"
package main; sub mlog {
    my ( $fh, $comment, $noprepend, $noipinfo , $noS) = @_;
    threads->yield();
    unless ($noS) {
        while (my $ar = shift @mlogS) {
            mlog(@$ar);
        }
    }
    $fh = 0 unless $fh;
    my $this = $fh ? exists $Con{$fh} ? $Con{$fh}: 0 : 0;
    my $header;
    my $noNotify = $comment =~ s/^\*x\*//o;
    my $logfile = $logfile;
    $logfile =~ s/\\/\//go;
    my $archivelogfile;
    my $archivelogfileBR;
    if ($WorkerNumber == 0) {
        if ($comment =~ /^(?:adminupdate|configerror)\:/io && ($WebIP{$ActWebSess}->{user} or $syncUser)) {
            $comment =~ s/^(adminupdate|configerror)(\:)/$1$2 \[$WebIP{$ActWebSess}->{user} $WebIP{$ActWebSess}->{ip}\]/io
                if (! $syncUser);
            $comment =~ s/^(adminupdate|configerror)(\:)/$1$2 \[$syncUser $syncIP\]/io
                if ($syncUser);
        }
        PrintConfigHistory($comment) if $comment =~ /^adminupdate/io;
        PrintConfigHistory($comment) if $comment =~ /^configerror/io;
        PrintAdminInfo($comment)     if $comment =~ /^admininfo/io;
        PrintAdminInfo($comment)     if $comment =~ /^email(?:[:])? /io;
        $lastMlog = time unless $comment;
    }

    my $m = &timestring();

    if($LogRollDays > 0 && $WorkerNumber == 0 && ! $comment) {

        # roll log every $LogRollDays days, at midnight
        my $t=int((time + TimeZoneDiff())/($LogRollDays*24*3600));
        if($logfile && $mlogLastT && $t != $mlogLastT && $logfile ne 'maillog.log' && $spamboxLog) {

            # roll the log
            my $mm = &timestring(time - 7200,'d',$LogNameDate);
            my ($logdir, $logdirfile);
            ($logdir, $logdirfile) = ($1,$2) if $logfile=~/^(.*)[\/\\](.*?)$/o;
            if (!$logdir)  {
                $archivelogfile = "$mm.$logfile";
                $archivelogfileBR = "$mm.b$logfile";
            } else {
                mkdir "$base/$logdir",0755;
                $archivelogfile = "$logdir/$mm.$logdirfile";
                $archivelogfileBR = "$logdir/$mm.b$logdirfile";
            }
            my $msg="$m: Rolling log file -- archive will be saved as '$archivelogfile'\n";
            w32dbg("$m: Rolling log file -- archive will be saved as '$archivelogfile'") if ($CanUseWin32Debug);
            print $LOG $msg if fileno($LOG);
            print $msg unless $silent;
            &closeLogs();
            sleep 1;
            $ThreadIdleTime{$WorkerNumber} += 1;
            if ($ExtraBlockReportLog) {
                rename("$base/$blogfile", "$base/$archivelogfileBR");
                my $e = $!;
                if ($e && ! -e "$base/$archivelogfileBR") {
                    print "error: unable to rename file $base/$blogfile to $base/$archivelogfileBR - $e\n";
                    threads->yield();
                    $mlogQueue->enqueue("error: unable to rename file $base/$blogfile to $base/$archivelogfileBR - $e\n");
                    threads->yield();
                }
            }
            rename("$base/$logfile", "$base/$archivelogfile");
            my $e = $!;
            if ($e && ! -e "$base/$archivelogfile") {
                print "error: unable to rename file $base/$logfile to $base/$archivelogfile - $e\n";
                threads->yield();
                $mlogQueue->enqueue("error: unable to rename file $base/$logfile to $base/$archivelogfile - $e\n");
                threads->yield();
            }
            &openLogs();
            print $LOG "$m $WorkerName new log file -- old log file renamed to '$archivelogfile'\n" if fileno($LOG);
            print $LOG "$m $WorkerName new blog file -- old log file renamed to '$archivelogfileBR'\n" if $ExtraBlockReportLog && fileno($LOG);
            w32dbg("$m $WorkerName new log file -- old log file renamed to '$archivelogfile'") if ($CanUseWin32Debug);
            w32dbg("$m $WorkerName new log file -- old log file renamed to '$archivelogfileBR'") if $CanUseWin32Debug && $ExtraBlockReportLog;
        }
        $mlogLastT=$t;
    }

    return 1 if((! $comment || $comment =~ /^[\s\r\n]+$/o) && ($fh == 0 || $WorkerNumber == 0));

    my @m;
    if ($this) {
        $m .= " $this->{msgtime}" if $this->{msgtime};
        if ($WorkerLogging) {
            $m .= " \[$WorkerName\]";
            if ("$fh" =~ /SSL/io or "$this->{friend}" =~ /SSL/io) {
                $m .= ("$fh" =~ /SSL/io && $this->{oldfh})
                    ? ' [TLS-in]' : ("$fh" =~ /SSL/io && ! $this->{oldfh})
                    ? ' [SSL-in]' : '';
                $m .= ("$this->{friend}" =~ /SSL/io && $Con{$this->{friend}}->{oldfh})
                    ? ' [TLS-out]' : ("$this->{friend}" =~ /SSL/io && ! $Con{$this->{friend}}->{oldfh})
                    ? ' [SSL-out]' : '';
            }
        }
        $m .= " $this->{prepend}" if $tagLogging && $this->{prepend} && !$noprepend;

        if ($expandedLogging || $noipinfo >= 2 || (! $this->{loggedIpFromTo} && !$noipinfo)) {
            $m .= " $this->{ip}" if ($this->{ip});
            $m .= " [OIP: $this->{cip}]" if ($this->{cip});
            my $mf = &batv_remove_tag(0,$this->{mailfrom},'');
            $m .= " <$mf>" if ($mf);
            my $to;
            $to = $this->{orgrcpt} if $noipinfo == 3;
            ($to) = $this->{rcpt} =~ /(\S+)/o unless $to;
            my $mm = $m;
            if ($to) {
                $this->{loggedIpFromTo} = 1 if $noipinfo < 3;
                $m .= " to: $to";
            }
            if ($noipinfo < 3 && $comment =~ / \[(?:spam found|MessageOK)\] /oi) {
                my $c = $comment;
                $c =~ s/\r//go;
                $c =~ s/\n([^\n]+)/\n\t$1/go;
                $c .= "\n" if ($c !~ /\n$/o);
                my %seen;
                for (split(/\s+/o,$this->{rcpt})) {
                    next unless $_;
                    next if $seen{lc $_};
                    $seen{lc $_} = 1;
                    push @m, "$mm to: $_ $c";
                }
            }
        }

        $m .= " $comment";
    } else {
        $m .= " \[$WorkerName\]" if $WorkerLogging;
        $m .= ' ' . ucfirst($comment);
    }

    if ($canNotify &&
        ! $noNotify &&
        scalar keys %NotifyRE &&
        $m =~ /$NotifyReRE/ &&
        $m !~ /$NoNotifyReRE/ &&
        NotifyFrequencyOK($comment) )
    {
        my $rcpt;
        my $sub;
        while (my ($k,$v) = each %NotifyRE) {
            if ($m =~ /$k/i) {
                ($rcpt = $v) or next;
                $sub = $NotifySub{$k} . " from $myName" if exists $NotifySub{$k};
                $sub ||= "SPAMBOX event notification from $myName [".substr($comment,0,40).']';
                &sendNotification(
                  $EmailFrom,
                  $rcpt,
                  $sub,
                  "log event on host $myName:\r\n\r\n$comment\r\n");
            }
        }
    }

    $m =~ s/\r//go;
    $m =~ s/\n([^\n]+)/\n\t$1/go;
    $m .= "\n" if ($m !~ /\n$/o);

    threads->yield();
    $debugQueue->enqueue(scalar @m ? @m : $m) if ($debug || $ThreadDebug);
    threads->yield();

    return 1 if($noLogLineRe && $m =~ /$noLogLineReRE/);

    if ($this) {
        if ($noLog && $fh && exists $Con{$fh} &&  ($this->{noLog} || $this->{nomlog} || &matchIP($Con{$fh}->{ip},'noLog',0,1) || ($Con{$fh}->{friend} && &matchIP($Con{$Con{$fh}->{friend}}->{ip},'noLog',0,1)))) {
            $this->{nomlog} = 1;
            return 1;
        }
        $header = substr($this->{header},0,$MaxBytes + $this->{headerlength}) if ($fh && $MaxBytes && !$this->{noLog} && $noLogRe);
        if ($this->{noLog} ||
            ($noLogRe &&
             (( $this->{mailfrom} && $this->{mailfrom} =~ /$noLogReRE/)
             || ( $header =~ /$noLogReRE/))))
        {
            $this->{noLog} = 1 if ($fh);
            return 1;
        }
    }
    
    threads->yield();
    $mlogQueue->enqueue(scalar @m ? @m : $m);
    threads->yield();
    $MainThreadLoopWait = 0;
    return 1;
}
