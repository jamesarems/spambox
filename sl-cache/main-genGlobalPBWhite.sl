#line 1 "sub main::genGlobalPBWhite"
package main; sub genGlobalPBWhite {
    return 0 if (! $pbdir);
    my $outfile = "$base/$pbdir/global/out/pbdb.white.db";
    my $tmpfile = "$base/$pbdir/global/out/pbdb.white.tmp";
    my $bakfile = "$base/$pbdir/global/out/pbdb.white.db.bak";
    $outfile =~ s/\\/\//go;
    $tmpfile =~ s/\\/\//go;
    $bakfile =~ s/\\/\//go;
    my $count = my $pbp = 0;
    my $t = ftime($outfile);
    (open my $OUT, '>',"$tmpfile") or return 0;
    binmode $OUT;
    while (my ($k,$v)=each(%PBWhite)) {
        my ($ct,$ut,$pbstatus,$reason)=split(/\s+/o,$v);
        my $tdifc=$t-$ct;
        my $tdifu=$t-$ut;
        $pbp++;
        &ThreadMaintMain2() if $WorkerNumber == 10000 && $pbp%1000 == 0;
        next if ($pbstatus != 2);
        next if ($tdifu > 0);                # was already processed before
        next if (delete $PBBlack{$k});       # should not be in PBBlack
        print $OUT "$k\002$ct $ut $pbstatus\n";
        $count++;
    }
    print $OUT "\n" if ($count == 0);
    close $OUT;
    return 1 if ($count == 0);
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
    mlog(0,"Info: global PBWhite with $count records created") if $MaintenanceLog;
    return 1;
}
