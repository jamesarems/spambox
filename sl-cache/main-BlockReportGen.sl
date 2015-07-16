#line 1 "sub main::BlockReportGen"
package main; sub BlockReportGen {
    my ( $now, $brfile ) = @_;
    my $fh = int( rand(time) );    # a dummy $fh for a dummy $Con{$fh}
    my $filename;
    my $number;
    my @lines;
    my $userq;
    d('BlockReportGen');
	if (! $CanUseNetSMTP) {
        my $i = $AvailNetSMTP ? 'enabled' : 'installed';
        mlog(0,"error: module Net::SMTP is not $i - unable to create a BlockReport");
        return;
    }
    ($filename) = $BlockReportFile =~ /file:(.+)/io if $BlockReportFile;
    if ( $now eq 'USERQUEUE' ) {
        $now      = '';
        $userq    = 1;
        $filename = "files/UserBlockReportQueue.txt";
    }

    $filename =
      $brfile
      ? "email block report list request from " . $Con{$brfile}->{mailfrom}
      : "$base/$filename";
    if ( ! $brfile ) {
        if (! -e "$filename" || -d "$filename" || ! (open $brfile,'<' ,"$filename")) {
            mlog(0,"error: unable to find or open the file $filename");
            return;
        }
    }
   # mlog( 0, "info: generating block reports from $filename" );

    my $BlModify;
    if (eval('use BlockReport::modify; BlockReport::modify::modify(); 1;')) {
        mlog(0,"info: BlockReport will call the module BlockReport::modify to make your custom changes") if $ReportLog > 1;
        $BlModify = \&BlockReport::modify::modify;
    } else {
        mlog(0,"info: BlockReport was unable to call the module BlockReport::modify - $@") if $ReportLog > 2;
        $BlModify = sub {return shift;};
    }

    while (<$brfile>) {
        s/\r|\n//go;
        my $cline = $_;
        my $comment; $comment = $1 if s/\s*#(.*)//go;

        if ( !$_ ) {
            push( @lines, $cline );
            next;
        }

        my $entrytime;
        my ( $addr, $to, $numdays, $exceptRe, $sched) = split( /\=\>/o, $_ );
        if ( $addr =~ /^\s*\#/o ) {
            push( @lines, $cline );
            next;
        }

        if ( ! $sched && $comment =~ /^\s*next\srun\s*\:\s*(\d+)[\-|\.](\d+)[\-|\.](\d+)/o )
        {
            my $year = $1;
            $year += $year < 100 ? 2000 : 0;
            eval { $entrytime = timelocal( 0, 0, 0, $3, $2 - 1, $1 - 1900 ); };
            if ($@) {
                mlog( 0,"error: wrong syntax in next-run-date (yyyy-mm-dd) at line <$cline> in $filename - $@")
                 if $ReportLog;
                $entrytime = 0;
            }
            if ( time < $entrytime && ! $now ) {
                push( @lines, $cline );
                next;
            }
        }
        $to = '' if ( $to =~ /\s*\*\s*/o );
        if ( $to && $to !~ /\s*($EmailAdrRe\@$EmailDomainRe)\s*/go ) {
            mlog( 0,"error: syntax error in send to address in $filename in entry $_" )
             if $ReportLog;
            push( @lines, $cline );
            next;
        }
        $to = $1 if $to =~ /\s*($EmailAdrRe\@$EmailDomainRe)\s*/go;
        ($numdays) = $numdays =~ /\s*(\d+)\s*/o;
        $numdays = 1 unless $numdays;
        if ( $addr !~ /.*?(\[?$EmailAdrRe|\*)\@($EmailDomainRe\]?|\*)/go ) {
            mlog( 0,"error: syntax error in report address in $filename in entry $_")
             if $ReportLog;
            push( @lines, $cline );
            next;
        }

        if ( !$now ) {
            if ( !$entrytime ) {
                my $time = time;
                my $dayoffset = $time % ( 24 * 3600 );
                $entrytime = $time - $dayoffset;
            }
            $entrytime = $numdays * 24 * 3600 + $entrytime;
            my (
                $second,    $minute,    $hour,
                $day,       $month,     $yearOffset,
                $dayOfWeek, $dayOfYear, $daylightSavings
            ) = localtime($entrytime);
            my $year = 1900 + $yearOffset;
            $month++;
            if ($userq) {
                if (! $sched && $comment =~ /^\s*next\srun\s*\:\s*\d+[\-|\.]\d+[\-|\.]\d+/o ) {
                    push( @lines, "$_ # next run: $year-$month-$day" );
                } elsif ($sched) {
                    $comment =~ s/^\s*next\srun\s*\:\s*\d+[\-|\.]\d+[\-|\.]\d+//o;
                    push( @lines, $comment ? "$_ # $comment" : $_ );
                } else {
                    push( @lines, $cline );
                }
            } else {
                if ($sched) {
                    $comment =~ s/^\s*next\srun\s*\:\s*\d+[\-|\.]\d+[\-|\.]\d+//o;
                    push( @lines, $comment ? "$_ # $comment" : $_ );
                } else {
                    push( @lines, "$_ # next run: $year-$month-$day" );
                }
            }
        } else {
            push( @lines, $cline );
        }
        if ($sched && ! $RunTaskNow{BlockReportNow}) {
            next;
        }
        my $mto;
        $mto = "to send it to $to" if $to;
        my $mfor = $addr;
        $mfor = "Group $addr" if $addr =~ /\[/o;
        mlog( 0, "info: generating block reports ($numdays) for $mfor $mto" )
          if $ReportLog >= 2;
        $Con{$fh}->{mailfrom} = $EmailAdminReportsTo;    # set to get all lines
        $Con{$fh}->{header} = "$addr=>$to=>$numdays=>$exceptRe\r\n";
        my $isGroup = $addr =~ s/\[(.+)\]/$1/o;

        my %user;
        &BlockReasonsGet( $fh, $numdays , \%user, $exceptRe);
        my @textreasons;
        my @htmlreasons;
        my $count;

        push( @textreasons, $user{sum}{textparthead} );
        push( @htmlreasons, $user{sum}{htmlparthead} );
        push( @htmlreasons, $user{sum}{htmlhead} );
        foreach  my $ad ( sort keys %user ) {
            next if ( $ad eq 'sum' );
            $number = scalar @{ $user{$ad}{text} } + $user{$ad}{correct};
            $number = 0 if $number < 0;
            $count += $number;
            $number = 'no' unless $number;
            my $rcpt = $to;
            if ( $addr !~ /\*/o || ( $addr =~ /\*/o && ! $to ) ) {
                $rcpt = $to ? $to : $addr;
                $rcpt = $rcpt =~ /\*/o ? $ad : $rcpt;
            }
            push( @textreasons,
                &BlockReportText( 'text', $ad, $numdays, $number, $rcpt ) );
            my $userhtml =
                &BlockReportText( 'html', $ad, $numdays, $number, $rcpt );
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
            while ( @{ $user{$ad}{html} } ) { push( @htmlreasons, BlockReportHTMLTextWrap(shift @{ $user{$ad}{html} })); }
            if ( ($addr !~ /\*/o && ! $isGroup) or ( $addr =~ /\*/o && ! $to ) ) {
                push( @textreasons, $user{sum}{text} );
                push( @htmlreasons, $user{sum}{html} );
                @textreasons = () if ( $BlockReportFormat == 2 );
                @htmlreasons = () if ( $BlockReportFormat == 1 );
                BlockReportSend(
                    $fh,
                    $rcpt,
                    $ad,
                    &BlockReportText( 'sub', $ad, $numdays, $number, $rcpt ),
                    $BlModify->($user{sum}{mimehead}
                      . join( '', @textreasons )
                      . join( '', @htmlreasons )
                      . $user{sum}{mimebot})
                ) if $count;
                @textreasons = ();
                @htmlreasons = ();

                push( @textreasons, $user{sum}{textparthead} );
                push( @htmlreasons, $user{sum}{htmlparthead} );
                push( @htmlreasons, $user{sum}{htmlhead} );
                $count = 0;
                next;
            }
        }
        if ($count) {
            push( @textreasons, $user{sum}{text} );
            push( @htmlreasons, $user{sum}{html} );
            @textreasons = () if ( $BlockReportFormat == 2 );
            @htmlreasons = () if ( $BlockReportFormat == 1 );
            BlockReportSend(
                $fh,
                $to,
                $addr,
                &BlockReportText( 'sub', $addr, $numdays, $count, $to ),
                $BlModify->($user{sum}{mimehead}
                  . join( '', @textreasons )
                  . join( '', @htmlreasons )
                  . $user{sum}{mimebot})
            );
        } else {
            if ( $addr =~ /\*/o and $to ) {
                my $for = $addr;
                $addr =~ s/\*\@//o;
                push( @textreasons,
"---------------------------------- $addr -----------------------------------\n\n"
                );
                push( @htmlreasons,BlockReportHTMLTextWrap(
"---------------------------------- $addr -----------------------------------<br />\n<br />\n")
                );
                push( @textreasons,
"\nno blocked email found for domain $addr in the last $numdays day(s)\n\n"
                );
                push( @htmlreasons,
"<br />\nno blocked email found for domain $addr in the last $numdays day(s)<br />\n<br />\n"
                );
                push( @textreasons, $user{sum}{text} );
                push( @htmlreasons, $user{sum}{html} );
                @textreasons = () if ( $BlockReportFormat == 2 );
                @htmlreasons = () if ( $BlockReportFormat == 1 );
                BlockReportSend(
                    $fh,
                    $to,
                    $for,
                    &BlockReportText( 'sub', $for, $numdays, $number, $to ),
                    $BlModify->($user{sum}{mimehead}
                      . join( '', @textreasons )
                      . join( '', @htmlreasons )
                      . $user{sum}{mimebot})
                );
            }
        }
        mlog( 0,
            "info: finished generating block reports ($numdays) for $addr $mto"
        ) if $ReportLog >= 2;

        @textreasons = ();
        @htmlreasons = ();
        %user        = ();
        delete $Con{$fh};
    }
    close $brfile;
    delete $Con{$fh};
    $filename="$base/$filename" if $filename!~/^\Q$base\E/io;
    if ( !$now && (open $brfile,'>' ,"$filename")) {
        binmode $brfile;
        print $brfile join("\n",@lines);
        print $brfile "\n";
        close $brfile;
    } elsif (! $now && $!) {
        mlog(0,"warning: error writing file $base/$filename - $!");
    }
    unloadNameSpace('BlockReport::modify');
}
