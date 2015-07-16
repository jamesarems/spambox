#line 1 "sub main::zipgz"
package main; sub zipgz {
    my ($infile,$outfile) = @_;
    my $gzerrno;
    mlog(0,"compressing file ".de8($infile)." to ".de8($outfile)) if ($MaintenanceLog);
    ($open->( my $IN, '<',$infile))
       || mlog(0,"Cannot open input file ".de8($infile).":\n") && return 0;
    ($open->( my $OUT, '>',$outfile))
       || mlog(0,"Cannot open output file ".de8($outfile).":\n") && return 0;

    (my $gz = gzopen($OUT, "wb"))
      || mlog(0,"Cannot open ".de8($outfile).": $gzerrno\n") && return 0;

    while (<$IN>) {
        $gz->gzwrite($_)
          || mlog(0,"error writing ".de8($outfile).": $gzerrno\n") && return 0;
    }

    $gz->gzclose ;
    $IN->close;
    return 1;
}
