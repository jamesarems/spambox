#line 1 "sub main::checkPluginData"
package main; sub checkPluginData {
    my ($fh,$data,$where,$pldo,$pltest,$plLogTo,$pl) = @_;
    my $this = $Con{$fh};
    d('checkPluginData: ' . $data);

    $data = e8($data) if $data;

    # here should be done all checks for data from Plugins like OCR
    # return 1 and '' for success
    # return 0 and SMTP error Reply for failed

    my $mbytes = $MaxBytes ? $MaxBytes : 10000;
    my $cbytes = $ClamAVBytes ? $ClamAVBytes : 20000;
    $cbytes = 100000 if $ClamAVBytes > 100000;
  
    setOverwriteDo($fh,'DoHMM',$pldo,$pl);
    $this->{hmmdone} = '';
    $this->{bayeslowconf} = '';
    @HmmBayWords = ();
    if ( ! HMMOK($fh,\substr($data, 0, $mbytes))) {
        $this->{overwritedo} = '';
        my $testmode;
        my $slok=$this->{allLoveBaysSpam}==1;
        $testmode = "HMM confidence low" if ($this->{bayeslowconf});
        $testmode = "testmode" if $baysTestMode || $pltest;
        $testmode = $slok = 0 if allSH($this->{rcpt},'baysSpamHaters');
        if (!$slok) { $Stats{bspams}++;}
        $this->{prepend}="[HMM]";
        delete $this->{clean} if ($slok || $testmode);
        return (0,'HMM',$SpamError,$spamPBLog || $plLogTo) if (! $slok && ! $testmode);
    }

    setOverwriteDo($fh,'DoBayesian',$pldo,$pl);
    $this->{bayesdone} = '';
    $this->{bayeslowconf} = '';
    if ( ! BayesOK($fh,\substr($data, 0, $mbytes),$this->{ip})) {
        $this->{overwritedo} = '';
        my $testmode;
        my $slok=$this->{allLoveBaysSpam}==1;
        $testmode = "bayes confidence low" if ($this->{bayeslowconf});
        $testmode = "testmode" if $baysTestMode || $pltest;
        $testmode = $slok = 0 if allSH($this->{rcpt},'baysSpamHaters');
        if (!$slok) { $Stats{bspams}++;}
        $this->{myheader}.=sprintf("X-Assp-Bayes-Confidence: %.5f\r\n",$this->{spamconf}) if $AddSpamProbHeader && $AddConfidenceHeader && $this->{spamconf}>0;
        $this->{prepend}="[Bayesian]";
        return (0,'Bayesian',$SpamError,$spamPBLog || $plLogTo) if (! $slok && ! $testmode);
    }
    delete $this->{clean};

    $this->{blackredone} = '';
    if (! BombBlackOK( $fh, \substr($data, 0, $mbytes)) ) {
        my $bomblt = $bombError;
        $bomblt .= " (reason: $this->{messagereason}) " if $bombErrorReason;
        $Stats{bombs}++;
        delayWhiteExpire($fh);
        my $slok = $this->{allLoveBoSpam} == 1;
        return (0,$this->{messagereason},$bomblt,$spamBombLog || $plLogTo) if (! $slok && ! $bombTestMode && ! $pltest);
    }

    setOverwriteDo($fh,'DoBombRe',$pldo,$pl);
    $this->{bombdone} = 'PL';           # tell BombOK that we are calling from here
    if (! BombOK( $fh, \substr($data, 0, $mbytes)) ) {
        $this->{overwritedo} = '';
        my $bomblt = $bombError;
        $bomblt .= " (reason: $this->{messagereason}) " if $bombErrorReason;
        $Stats{bombs}++;
        delayWhiteExpire($fh);
        my $slok = $this->{allLoveBoSpam} == 1;
        return (0,$this->{messagereason},$bomblt,$spamBombLog || $plLogTo) if (! $slok && ! $bombTestMode && ! $pltest);
    }

    setOverwriteDo($fh,'UseAvClamd',$pldo,$pl);
    $this->{clamscandone} = '';
    if (! ClamScanOK($fh,\substr($data, 0, $cbytes))){
        $this->{overwritedo} = '';
        $this->{prepend}="[VIRUS]";
        return (0,$this->{messagereason},$this->{averror},$SpamVirusLog || $plLogTo) if (! $pltest);
    }

    setOverwriteDo($fh,'DoFileScan',$pldo,$pl);
    $this->{filescandone} = '';
    if (! FileScanOK($fh,\substr($data, 0, $cbytes))){
        $this->{overwritedo} = '';
        $this->{prepend}="[VIRUS]";
        return (0,$this->{messagereason},$this->{averror},$SpamVirusLog || $plLogTo) if (! $pltest);
    }

    setOverwriteDo($fh,'DoScriptRe',$pldo,$pl);
    $this->{ScriptOK} = '';
    if(! ScriptOK($fh,\substr($data, 0, $mbytes))) {
        $this->{overwritedo} = '';
        my $slok=$this->{allLoveBoSpam}==1;
        $Stats{scripts}++;
        delayWhiteExpire($fh);
        my $bomblt = $scriptError;

        $bomblt .= " (reason: $this->{messagereason}) " if $bombErrorReason;
        $this->{prepend}="[BombScript]";
        return (0,$this->{messagereason},$bomblt,$scriptLog || $plLogTo) if (! $slok && ! $bombTestMode && ! $pltest);
    }

    setOverwriteDo($fh,'ValidateURIBL',$pldo,$pl);
    $this->{skipuriblPL} = 1;
    $this->{uribldone} = '';
    if(! URIBLok($fh,\substr($data, 0, $mbytes),$this->{ip},1)) {
        $this->{skipuriblPL} = '';
        $this->{overwritedo} = '';
        my $slok=$this->{allLoveURIBLSpam}==1;
        delayWhiteExpire($fh);
        my $err=$URIBLError;
        $err=~s/URIBLNAME/$this->{uri_listed_by}/go;
        delete $this->{uri_listed_by};
        return (0,$this->{messagereason},$err,$URIBLFailLog || $plLogTo) if (! $slok && ! $uriblTestMode && ! $pltest);
    }
    $this->{skipuriblPL} = '';

    $this->{overwritedo} = '';
    return 1,'','',$plLogTo;  # res reason Reply log
}
