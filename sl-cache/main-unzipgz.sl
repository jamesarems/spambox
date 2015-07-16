#line 1 "sub main::unzipgz"
package main; sub unzipgz {
  my ($infile,$outfile) = @_;
  my $buffer ;
  my $gzerrno;
  return 0 unless $CanUseHTTPCompression;
  mlog(0,"decompressing file $infile to $outfile") if $MaintenanceLog;
  eval{
  ($open->( my $OUTFILE, '>',$outfile)) or die 'unable to open '.de8($outfile)."\n";
  ($open->( my $INFILE, '<',$infile)) or die 'unable to open '.de8($infile)."\n";
  $OUTFILE->binmode;
  my $gz = gzopen($INFILE, 'rb') or die 'unable to open '.de8($infile)."\n";
  while ($gz->gzread($buffer) > 0) {
      $OUTFILE->print($buffer);
  }
  $gzerrno != Z_STREAM_END() or die 'unable to read from '.de8($infile).": $gzerrno" . ($gzerrno+0)."\n";
  $gz->gzclose() ;
  $OUTFILE->close;
  };
  if ($@) {
      mlog(0,"error : gz - $@");
      return 0;
  }
  return 1;
}
