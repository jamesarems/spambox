#line 1 "sub main::NoLoopSyswrite"
package main; sub NoLoopSyswrite {
    my ($fh,$out,$timeout) = @_;
    d('NoLoopSyswrite');
    return 0 unless fileno($fh);
    return 0 unless $out;
    $timeout ||= 30;
    my $written = 0;
    my $ip;
    my $port;
    my $error;
    eval{
      $ip=$fh->peerhost();
      $port=$fh->peerport();
    };
    if($@) {$! = $@; return 0;};
    d("NoLoopSyswrite - write($timeout $fh): '" . substr($out,0,30) . '\' - ' . length($out));
    &sigoffTry(__LINE__);
    
    if (   exists $Con{$fh}
        && $Con{$fh}->{type} eq 'C'       # is a client SMTP connection?
        && ($replyLogging == 2 or ($replyLogging == 1 && $out =~ /^[45]/o))
        && $out =~ /^(?:[1-5]\d\d\s+[^\r\n]+\r\n)+$/o)    # is a reply?
    {
        $out =~ s/SESSIONID/$Con{$fh}->{msgtime} $Con{$fh}->{SessionID}/go;
        $out =~ s/MYNAME/$myName/go;
        my @reply = split(/(?:\r?\n)+/o,$out);
        for (@reply) {
            next unless $_;
            my $what = 'Reply';
            if ($_ =~ /^([45])/o) {
                $what = ($1 == 5) ? 'Error' : 'Status';
            }
            $out =~ s/NOTSPAMTAG/NotSpamTagGen($fh)/ge if $what eq 'Error';
            mlog( $fh, "[SMTP $what] $_", 1, 1 );
        }
    }

    my $stime = Time::HiRes::time() + $timeout;
    my $wtime = Time::HiRes::time() + 1;
    my $NLwritable;
    if ($IOEngineRun == 0) {
        $NLwritable = IO::Poll->new();
    } else {
        $NLwritable = IO::Select->new();
    }
    &dopoll($fh,$NLwritable,POLLOUT);
    my $l = length($out);
    my $allwritten = 0;
    while (length($out) > 0 && fileno($fh) && Time::HiRes::time() < $stime) {
        my @canwrite;
        my $st = Time::HiRes::time();
        if ($IOEngineRun == 0) {
            $NLwritable->poll(1);
            @canwrite = $NLwritable->handles(POLLOUT);
        } else {
            @canwrite = $NLwritable->can_write(1);
        }
        my $polltime = Time::HiRes::time() - $st;
        $ThreadIdleTime{$WorkerNumber} += $polltime;
        mlog(0,"warning: the operating system socket poll cycle has taken $polltime seconds in NoLoopSyswrite - this is very much is too long")
            if ($ConnectionLog >= 2 and $polltime > 3);
        $written = 0;
        $error = 0;
        eval{$written = $fh->syswrite($out,length($out));
             $error = $!;
             $error = '' if ("$fh" =~ /SSL/io && ($IO::Socket::SSL::SSL_ERROR == eval('SSL_WANT_READ') ? 1 : $IO::Socket::SSL::SSL_ERROR == eval('SSL_WANT_WRITE') ) );
        } if @canwrite or "$fh" =~ /SSL/io;
        $allwritten += $written;
        if (@canwrite && ! $written && ($@ or $error)) {
            my $er = $error . $@;
            if ($ConnectionLog == 3 && ! ($WorkerNumber == 0 && $er =~ /Wide character in syswrite/io)) {
                mlog(0,"warning: unable to write to socket $ip:$port $error") if $error;
                mlog(0,"warning: unable to write to socket $ip:$port $@") if $@;
            }
            $! = $error;
            unpoll($fh,$NLwritable);
            &sigonTry(__LINE__);
            return 0;
        }
        if ($written) {
            $out = substr($out,$written);
            $Con{$fh}->{lastwritten} = time if exists $Con{$fh};
        }
        if ($WorkerNumber == 0 && $timeout > 1 && $wtime < Time::HiRes::time()) {
            &mlogWrite;
            $wtime = Time::HiRes::time() + 1;
        }
        if ($WorkerNumber == 10000 && ! $isRunTMM2 && length($out) && time % 2) {
            my $tt = Time::HiRes::time();
            ThreadMaintMain2();
            $stime += Time::HiRes::time() - $tt;
        }
    }
    d("NoLoopSyswrite - wrote: $allwritten to $fh");
    unpoll($fh,$NLwritable);
    if (time >= $stime) {
        mlog(0,"warning: timeout (30s) writing to socket $ip:$port") if $ConnectionLog == 3;
    }
    &sigonTry(__LINE__);
    return 1;
}
