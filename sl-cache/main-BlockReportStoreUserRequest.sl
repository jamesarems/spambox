#line 1 "sub main::BlockReportStoreUserRequest"
package main; sub BlockReportStoreUserRequest {
    my ( $from, $sub, $oldrequest ) = @_;
    my $request=$oldrequest;
    my $file = "$base/files/UserBlockReportQueue.txt";
    $file = "$base/files/UserBlockReportInstantQueue.txt" if $oldrequest>=3;

    $request=1 if $oldrequest>=3;
    my %lines = ();
    my ( $user, $to, $numdays, $nextrun, $comment, $exceptRe , $sched);
    my $reply;

    open my $f, '<',"$file";
    while (<$f>) {
        s/\r?\n//igo;
        s/\s*#(.*)//go;
        $comment = $1;
        next unless $_;
        ( $user, $to, $numdays , $exceptRe , $sched) = split( /\=\>/o, $_ );
        next unless $user;
        $comment =~ /^\s*(next\srun\s*\:\s*\d+[\-|\.]\d+[\-|\.]\d+)/o;
        $nextrun               = $1 ? "# $1" : '';
        $user                  = lc($user);
        $numdays               = 5 unless $numdays;
        $lines{$user}{numdays} = $numdays;
        $lines{$user}{nextrun} = $nextrun;
        $lines{$user}{exceptRe} = $exceptRe;
        $lines{$user}{sched} = $sched;
    }
    close $f;
    $from = lc($from);
    $sub =~ /^\s*([+\-])?(?:(?:\s*|\s*=>\s*)(\d+))?(?:(?:\s+|\s*=>\s*)([^\s]+))?(?:(?:\s+|\s*=>\s*)($ScheduleRe(?:\|$ScheduleRe)*))?\s*$/o;
    my $how = $1;
    $numdays = $2 ? $2 : 5;
    $exceptRe = $3;
    $sched = $4;
    if ( $how eq '-' ) {
        if (delete $lines{$from}) {
            mlog( 0, "info: removed entry for $from from block report queue" )
              if $ReportLog >= 2;
            $reply = "your entry $from was removed from the block report queue!\n";
        } else {
            $reply = "an entry $from was not found in the block report queue!\n";
        }
    } else {
        my $time = time;
        my $dayoffset = $time % ( 24 * 3600 );
        $nextrun = $time - $dayoffset + ( 24 * 3600 );
        my (
            $second,    $minute,    $hour,
            $day,       $month,     $yearOffset,
            $dayOfWeek, $dayOfYear, $daylightSavings
        ) = localtime($nextrun);
        my $year = 1900 + $yearOffset;
        $month++;
        $nextrun = "# next run: $year-$month-$day";
        $nextrun = '' if ( $request < 2 && $how ne '+' );

        if ($exceptRe) {
            eval{'a' =~ /$exceptRe/i};
            if ($@) {
                mlog(0,"error: regex error in blockreport request from $from - $sub - $@") if $ReportLog;
                $reply = "Your entry $from was not processed - bad regex found - $@ !\n";

                my $fh = int( rand(time) );    # a dummy $fh for a dummy $Con{$fh}
                $Con{$fh}->{mailfrom} = $from;
                BlockReportSend(
                    $fh,
                    $from,
                    $from,
                    &BlockReportText( 'sub', $from, $numdays, 'n/a', $from )
                      . " - Block Report Queue ",
                    $reply
                );
                delete $Con{$fh};
                return;
            }
        }

   		if ( exists $lines{$from} ) {
            $reply = "Your entry $from was updated in the block report queue!\n";
            mlog( 0, "info: updated entry for $from in block report queue" )
              if $oldrequest <3 && $ReportLog >= 2;
            mlog( 0, "info: updated entry for $from in block report instant queue" )
              if $oldrequest =3 && $ReportLog >= 2;
    	} else {
            $reply = "Your entry $from was added to the block report queue!\n";
            mlog( 0, "info: added entry for $from to block report queue" )
              if $oldrequest <3 && $ReportLog >= 2;
            mlog( 0, "info: added entry for $from to block report instant queue" )
              if $oldrequest =3 && $ReportLog >= 2;
    	}
        $lines{$from}{numdays} = $numdays;
        $lines{$from}{nextrun} = $nextrun;
        $lines{$from}{exceptRe} = $exceptRe;
        $lines{$from}{sched} = $sched;
    }
    my $time = time;
    open $f, '>',"$file";
    while ( !($f->opened) && time - $time < 10 ) { sleep 1; $ThreadIdleTime{$WorkerNumber} += 1 ;open $f, '>',"$file"; }
    if ($f->opened) {
        binmode $f;
        foreach my $line ( sort keys %lines ) {
            $lines{$line}{exceptRe} =~ s/^\s*(.*?)\s*$/$1/o;
            print $f $line . '=>'
              . $line . '=>'
              . $lines{$line}{numdays} . '=>'
              . $lines{$line}{exceptRe} . ($lines{$line}{sched} ? '=>' : ' ')
              . $lines{$line}{sched}
              . ($lines{$line}{sched} ? ' ' : '')
              . $lines{$line}{nextrun} . "\n";
        }
        close $f;
    } else {
        $reply =~ s/ was / was not /o;
        $reply .= " Internal write error, please contact your email admin!";
        mlog( 0,"error: unable to open $file for write within 10 seconds - entry for $from not updated" )
          if $ReportLog;
    }
    my $fh = int( rand(time) );    # a dummy $fh for a dummy $Con{$fh}
    $Con{$fh}->{mailfrom} = $from;
    BlockReportSend(
        $fh,
        $from,
        $from,
        &BlockReportText( 'sub', $from, $numdays, 'n/a', $from )
          . " - Block Report Queue ",
        $reply
    ) if $oldrequest < 3;
    delete $Con{$fh};
}
