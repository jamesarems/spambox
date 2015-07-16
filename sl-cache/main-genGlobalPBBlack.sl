#line 1 "sub main::genGlobalPBBlack"
package main; sub genGlobalPBBlack {
    return 0 if (! $pbdir);
    my $outfile = "$base/$pbdir/global/out/pbdb.black.db";
    my $tmpfile = "$base/$pbdir/global/out/pbdb.black.tmp";
    my $bakfile = "$base/$pbdir/global/out/pbdb.black.db.bak";
    $outfile =~ s/\\/\//go;
    $tmpfile =~ s/\\/\//go;
    $bakfile =~ s/\\/\//go;
    my $count = my $pbp = 0;
    my $t = ftime($outfile);
    (open my $OUT, '>',"$tmpfile") or return 0;
    binmode $OUT;
    while (my ($k,$v)=each(%PBBlack)) {
        my ($ct,$ut,$pbstatus,$score,$sip,$reason)=split(/\s+/o,$v);
        my $tdifc=$t-$ct;
        my $tdifu=$t-$ut;
        $pbp++;
        &ThreadMaintMain2() if $WorkerNumber == 10000 && $pbp%1000 == 0;
        next if ($reason =~ /GLOBALPB/io);      # no global back to server
        next if ($pbstatus < 3);             # must be min 3 times in local PB
        next if ($tdifu > 0);                # was already processed before
        next if ($score < 1);                # no negative Black
        next if (delete $PBWhite{$k});       # should not be in PBWhite
        print $OUT "$k\002$v\n";
        $count++;
    }
    print $OUT "\n" if ($count == 0);
    close $OUT;
    $! = undef;
    if (-e "$bakfile") {
        unlink($bakfile);
        if ($!) {
           mlog(0,"unable to delete file $bakfile - $!");
           return 0;
        }
    }
    $! =undef;
    rename("$outfile", "$bakfile") if (-e "$outfile");
    if ($! && -e "$outfile") {
        mlog(0,"unable to rename file $outfile to $bakfile - $!");
        return 0;
    }
    $! = undef;
    rename("$tmpfile", "$outfile");
    if ($! && -e "$tmpfile") {
        mlog(0,"unable to rename file $tmpfile to $outfile - $!");
        return 0;
    }
    mlog(0,"Info: global PBBlack with $count records created") if $MaintenanceLog;
    return 1;
}
