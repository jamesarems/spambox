#line 1 "sub main::haveToScan"
package main; sub haveToScan {
    my $fh=shift;
    return 0 unless $fh;
    my $this=$Con{$fh};

    my $UseAvClamd = $UseAvClamd;    # copy the global to local - using local from this point
    $UseAvClamd = $this->{overwritedo} if ($this->{overwritedo});   # overwrite requ by Plugin

    return 0 if !$UseAvClamd;
    return 0 if !$CanUseAvClamd;
    return 0 if $this->{noscan};
    return 0 if $this->{clamscandone}==1;
    return 0 if $this->{whitelisted} && $ScanWL!=1;
    return 0 if ($this->{noprocessing} & 1) && $ScanNP!=1;
    return 0 if $this->{relayok} && $ScanLocal!=1;
    if (matchSL($this->{mailfrom},'noScan')) {
        $this->{noscan} = 1;
        return 0;
    }

    if ((matchIP($this->{ip},'noScanIP',$fh,0)) ||
        ($NoScanRe  && $this->{ip}=~/$NoScanReRE/) ||
        ($NoScanRe  && $this->{helo}=~/$NoScanReRE/) ||
        ($NoScanRe  && $this->{mailfrom}=~/$NoScanReRE/))
    {
        $this->{noscan} = 1;
        return 0;
    }

    $this->{prepend}='';

    return 1;
}
