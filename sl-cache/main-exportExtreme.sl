#line 1 "sub main::exportExtreme"
package main; sub exportExtreme {
    d('exportExtreme');
    return 0 unless $DoExtremeExport;

    my $fil;
    if ( $exportExtremeBlack =~ /^\s*file:\s*(.+)\s*$/io ) {
        $fil = $1;
    } else {
        return;
    }
    $fil = "$base/$fil" if $fil !~ /^(([a-z]:)?[\/\\]|\Q$base\E)/io;

    my %extremeips;
    keys %extremeips = 1024;
    # import existing extreme IP's
    my $counter = my $pbp = 0;
    if ( $DoExtremeExportAppend ) {
        my $r;
        open( my $IMPORT,'<', "$fil" );
        local $/ = "\n";
        while ( $r = <$IMPORT> ) {
            $r =~ y/\r\n\t //d;
            next unless $r;
            $extremeips{$r} = 1;
            $counter++;
        }
        close $IMPORT;
        mlog( 0, "PenaltyBox: $fil read, imported:$counter" ) if $MaintenanceLog;
    }

    &ThreadMaintMain2() if $WorkerNumber == 10000;

    # get additional extreme IP's from PenaltyBlack
    my ( $ct, $ut, $pbstatus, $score, $sip, $reason );
    while ( ( my $k, my $v ) = each(%PBBlack) ) {
        ( $ct, $ut, $pbstatus, $score, $sip, $reason ) = split( ' ', $v );

        $pbp++;
        &ThreadMaintMain2() if $WorkerNumber == 10000 && $pbp % 1000 == 0;
        next if $k =~ /\.0$/o;
        next if $reason =~ /GLOBALPB/io;

        # skip, IP already exists in extreme file
        next if $extremeips{$k};

        if ( $score >= $PenaltyExtreme ) {
            $extremeips{$k} = 1;
            $counter++;
        }
    }

    # write extreme temp file
    my $EXPORT;
    $pbp = 0;
    open( $EXPORT,'>' ,"$fil.tmp" );
    foreach my $e ( sort keys %extremeips ) {
        $pbp++;
        &ThreadMaintMain2() if $WorkerNumber == 10000 && $pbp % 1000 == 0;
        next unless $e;
        print $EXPORT "$e\n";
    }
    close $EXPORT;

    # backup and swap in new extreme file
    unlink( "$fil.bak" );
    move( "$fil", "$fil.bak" );
    move( "$fil.tmp", "$fil" );

    mlog( 0, "PenaltyBox: $fil exported, entries:$counter" ) if $MaintenanceLog;
    return 1;
}
