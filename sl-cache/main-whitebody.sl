#line 1 "sub main::whitebody"
package main; sub whitebody { my($fh,$l)=@_;
    my $this=$Con{$fh};
    d('whitebody');
    my $server=$this->{friend};
    $this->{maillength}+=length($l);
    $this->{header} .= $l;
    my $mbytes;
    my $clamavbytes;

    return if ! MessageSizeOK($fh);
    
    my $done=$l=~/^\.[\r\n]*$/o || defined($this->{bdata}) && $this->{bdata}<=0;

    $this->{headerlength} ||= getheaderLength($fh);
    $mbytes = $MaxBytes ? $MaxBytes + $this->{headerlength} : 10000 + $this->{headerlength};
    $clamavbytes = $ClamAVBytes ? $ClamAVBytes + $this->{headerlength} : 50000 + $this->{headerlength};
    $clamavbytes = 100000 if $ClamAVBytes > 100000;
    $mbytes = $clamavbytes
      if $clamavbytes > $mbytes && ($BlockExes || $CanUseAvClamd && $AvailAvClamd) ;
    $mbytes = 100000 if $mbytes > 100000;

    $this->{headerpassed} = 1 if ($done || $this->{maillength} >= $mbytes );

    my $doneToError = $done || ($send250OK || ($send250OKISP && ($this->{ispip} or $this->{cip})));
    if (($done || $this->{maillength} >= $mbytes ) && haveToScan($fh) &&
         ! ClamScanOK($fh, bodyWrap(\$this->{header},$clamavbytes)))
    {
            thisIsSpam($fh,$this->{messagereason},$SpamVirusLog,$this->{averror},0,0,$doneToError);
            return;
    }
    if (($done || $this->{maillength} >= $mbytes ) && haveToFileScan($fh) &&
         ! FileScanOK($fh, bodyWrap(\$this->{header},$clamavbytes)))
    {
            thisIsSpam($fh,$this->{messagereason},$SpamVirusLog,$this->{averror},0,0,$doneToError);
            return;
    }

    if($done) {
        $this->{getline}=\&getline;
        &addMyheader($fh) if $this->{myheader};
    }
    sendquedata($server, $fh , \$l , $done);
}
