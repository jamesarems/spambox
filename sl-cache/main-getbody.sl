#line 1 "sub main::getbody"
package main; sub getbody {
    my ( $fh, $l ) = @_;
    my $this = $Con{$fh};
    my $dataref;
    my $virusdataref;

    $this->{datastart} = $this->{maillength} if (! $this->{datastart});
    $this->{maillength}+=length($l);
    $this->{header} .= $l;

    $this->{headerlength} ||= getheaderLength($fh);
    my $maxbytes = $MaxBytes ? $MaxBytes + $this->{headerlength} : 10000 + $this->{headerlength};
    my $clamavbytes = $ClamAVBytes ? $ClamAVBytes + $this->{headerlength} : 50000 + $this->{headerlength};
    $clamavbytes = 100000 if $ClamAVBytes > 100000;
    my $mbytes = $maxbytes;
    $mbytes = $clamavbytes
      if $clamavbytes > $mbytes && ($BlockExes || $CanUseAvClamd && $AvailAvClamd) ;

    my $done = $l =~ /^\.[\r\n]*$/o || defined( $this->{bdata} ) && $this->{bdata} <= 0;

    if ( $done || $this->{maillength} >= $mbytes) {
        my $doneToError = $done || ($send250OK || ($send250OKISP && ($this->{ispip} or $this->{cip})));

        $this->{skipnotspam} = 1;
        
        $dataref = bodyWrap(\$this->{header},$maxbytes);
        $virusdataref = bodyWrap(\$this->{header},$clamavbytes);

        $this->{attachcomment} = "no bad attachments";

        d( "getbody - done:$done maillength:$this->{maillength}" );

        if ( !$this->{red} && $redRe && $$dataref =~ /($redReRE)/ )	{
            $this->{red} = ($1||$2);
            mlogRe( $fh, $this->{red}, 'redRe','redlisting' );
        }

        if ( !$this->{whitelisted} && $whiteRe && $$dataref =~ /($whiteReRE)/ ) {
            $this->{whitelisted} = 1;
            mlogRe( $fh, ($1||$2), 'whiteRe','whitelisting' );
        }

        if ( !($this->{noprocessing} & 1) && $npRe && $$dataref=~/($npReRE)/) {
            mlogRe($fh,($1||$2),'npRe','noprocessing');
            pbBlackDelete($fh,$this->{ip});
            $this->{noprocessing} = 1;
        }

        if ( !$this->{spamlover} & 1 && $SpamLoversRe && $$dataref=~/($SpamLoversReRE)/ ) {
            mlogRe($fh,($1||$2),'SpamLoversRe','spamlovers');
            $this->{spamlover} = 3;
        }

        if(!$this->{contentonly} && $contentOnlyRe && $this->{header} =~ /($contentOnlyReRE)/) {
            mlogRe($fh,($1||$2),'contentOnlyRe','contentonly');
            pbBlackDelete($fh,$this->{ip});
            $this->{contentonly} = 1;
            $this->{ispip} = 1;
        }

        if (&MsgScoreTooHigh($fh,$doneToError)) {$this->{skipnotspam} = 0;return;}

        my $attBlock = $BlockExes;
        $attBlock = $BlockWLExes if $this->{whitelisted} || $this->{relayok};
        $attBlock = $BlockNPExes if $this->{noprocessing};
        if ( ! CheckAttachments( $fh, $attBlock, $dataref, $extAttachLog, $doneToError ) ) {
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$doneToError)) {$this->{skipnotspam} = 0;return;}

        if ( ! BombOK( $fh, $dataref ) ) {
            my $bomblt = $bombError;

            $bomblt .= " (reason: $this->{messagereason}) " if $bombErrorReason;
            $Stats{bombs}++;
            delayWhiteExpire($fh);
            my $slok = $this->{allLoveBoSpam} == 1;

            thisIsSpam( $fh, $this->{messagereason}, $spamBombLog, $bomblt, $bombTestMode, $slok, $doneToError );
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$doneToError)) {$this->{skipnotspam} = 0;return;}

        if(! ScriptOK($fh,$dataref)) {
            my $slok=$this->{allLoveBoSpam}==1;
            $Stats{scripts}++;
            delayWhiteExpire($fh);
            my $bomblt = $scriptError;

            $bomblt .= " (reason: $this->{messagereason}) " if $bombErrorReason;
            $this->{prepend}="[BombScript]";
            thisIsSpam($fh,$this->{messagereason},$scriptLog,$bomblt,$bombTestMode,$slok,$doneToError);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$doneToError)) {$this->{skipnotspam} = 0;return;}

        if(! BombBlackOK($fh, $dataref)) {
            my $bomblt = $bombError;
            $bomblt .= " (reason: $this->{messagereason}) " if $bombErrorReason;
            delayWhiteExpire($fh);
            my $slok=$this->{allLoveBoSpam}==1;
            $Stats{bombs}++;
            thisIsSpam($fh,$this->{messagereason},$spamBombLog,$bomblt,$bombTestMode,$slok,$doneToError);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$doneToError)) {$this->{skipnotspam} = 0;return;}

        if ( haveToScan($fh) && ! ClamScanOK($fh,$virusdataref)){
            $this->{prepend}="[VIRUS]";
            thisIsSpam($fh,$this->{messagereason},$SpamVirusLog,$this->{averror},0,0,$doneToError);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$doneToError)) {$this->{skipnotspam} = 0;return;}

        if ( haveToFileScan($fh) && ! FileScanOK($fh,$virusdataref)){
            $this->{prepend}="[VIRUS]";
            thisIsSpam($fh,$this->{messagereason},$SpamVirusLog,$this->{averror},0,0,$doneToError);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$doneToError)) {$this->{skipnotspam} = 0;return;}

        if(! $this->{uribldone} && ! URIBLok($fh,$dataref,$this->{ip},$doneToError)) {
            delayWhiteExpire($fh);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$doneToError)) {$this->{skipnotspam} = 0;return;}

        if($this->{addressedToSpamBucket} && ! $this->{SpamCollectAddress}) {
            $this->{SpamCollectAddress} = 1;
            $Stats{spambucket}++ ;
            $this->{messagereason}="Collect Address: $this->{addressedToSpamBucket}";
            pbAdd($fh,$this->{ip},'saValencePB','SpamCollectAddress',2);
            $this->{prepend}="[Collect]";
            thisIsSpam($fh,"Collect Address: $this->{addressedToSpamBucket}",$spamBucketLog,"250 OK",0,0,0);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$doneToError)) {$this->{skipnotspam} = 0;return;}

        @HmmBayWords = ();
        if( ! HMMOK($fh,$dataref)) {
            my $slok=$this->{allLoveBaysSpam}==1;
            my $mybaystestmode;
            $mybaystestmode = "1" if $this->{bayeslowconf} || $baysTestMode;
            $mybaystestmode = $slok = 0 if allSH($this->{rcpt},'baysSpamHaters');
            if (!$slok) { $Stats{bspams}++;}
            $this->{myheader}.=sprintf("X-Assp-HMM-Confidence: %.5f\r\n",$this->{hmmconf}) if $AddSpamProbHeader && $AddConfidenceHeader && $this->{hmmconf}>0;
            $this->{prepend}="[HMM]";
            thisIsSpam($fh,'HMM',$baysSpamLog,$SpamError,$mybaystestmode,$slok,$doneToError);
            if ($this->{error}) {$this->{skipnotspam} = 0; delete $this->{clean}; return;}
        }
        if (&MsgScoreTooHigh($fh,$doneToError)) {$this->{skipnotspam} = 0; delete $this->{clean}; return;}

        my $bayeslowconf = $this->{bayeslowconf};
        $this->{bayeslowconf} = '';
        if( ! BayesOK($fh,$dataref,$this->{ip})) {
            my $slok=$this->{allLoveBaysSpam}==1;
            my $mybaystestmode; 
            $mybaystestmode = "1" if $this->{bayeslowconf} || $baysTestMode;
            $mybaystestmode = $slok = 0 if allSH($this->{rcpt},'baysSpamHaters');
            if (!$slok) { $Stats{bspams}++;}
            $this->{myheader}.=sprintf("X-Assp-Bayes-Confidence: %.5f\r\n",$this->{spamconf}) if $AddSpamProbHeader && $AddConfidenceHeader && $this->{spamconf}>0;
            $this->{prepend}="[Bayesian]";
            thisIsSpam($fh,'Bayesian',$baysSpamLog,$SpamError,$mybaystestmode,$slok,$doneToError);
            if ($this->{error}) {$this->{skipnotspam} = 0; delete $this->{clean}; return;}
        }
        delete $this->{clean};
        $this->{bayeslowconf} ||= $bayeslowconf;
        if (&MsgScoreTooHigh($fh,$doneToError)) {$this->{skipnotspam} = 0;return;}

        if (&TestLowMessageScore($fh)) {
            $this->{messagelow}=1;
            $this->{messagereason}="MessageScore passed low limit";
            my $slok=$this->{allLovePBSpam}==1;
            my $er = $SpamError;
            $er = $PenaltyError if $PenaltyError;
            $this->{prepend}="[MessageLimit]";
            delayWhiteExpire($fh);
            $Stats{msgscoring}++;
            thisIsSpam($fh,$this->{messagereason},$spamMSLog,$er,$msTestMode,$slok,$doneToError);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        if (&MsgScoreTooHigh($fh,$doneToError)) {$this->{skipnotspam} = 0;return;}

        if (! PBOK($fh,$this->{ip})){
            my $slok=$this->{allLovePBSpam}==1;
            unless ($slok) {$Stats{pbdenied}++;}
            my $er=$SpamError;
            $er=$PenaltyError if $PenaltyError;
            $this->{myheader}.="X-Assp-Penalty: $this->{messagereason}\r\n";
            $this->{prepend}="[Penalty]";
            thisIsSpam($fh,$this->{messagereason},$spamPBLog,$er,$pbTestMode || $DoPenalty == 4,$slok,$doneToError);
            if ($this->{error}) {$this->{skipnotspam} = 0;return;}
        }
        $this->{TestMessageScore} = 1;
        if (&MsgScoreTooHigh($fh,$doneToError)) {delete $this->{TestMessageScore};$this->{skipnotspam} = 0;return;}

        delete $this->{TestMessageScore};
        $this->{skipnotspam} = 0;
        if($this->{spamfound}) {

            # Spam is found to be safe, lets pass it on.
            my $fn;
            if (! $this->{maillogfh}) {
                $fn = Maillog($fh,'',$baysSpamLog);
            } else {
                $fn = $this->{maillogfilename};
            }
            $fn=' -> '.$fn if $fn ne '';
            $fn='' if !$fileLogging;
            my $logsub =
                  ( $subjectLogging ? " $subjectStart$this->{originalsubject}$subjectEnd" : '' );
            mlog($fh,"spam found and passing ($this->{messagereason})$logsub".de8($fn),1);
            delayWhiteExpire($fh);
            isnotspam($fh,$done);
            return;
        }
        my $fn;
        my $logto = ($this->{relayok} || $this->{whitelisted}) ? $NonSpamLog : $baysNonSpamLog;
        $logto = $noProcessingLog if $this->{noprocessing};
        if (! $this->{maillogfh}) {
            $fn = Maillog($fh,'',$logto) if $logto>=2 ;
        } else {
            $fn = $this->{maillogfilename} if $logto>=2 ;
        }
        $fn=' -> '.$fn if $fn ne '';
        $fn='' if !$fileLogging;
        my $pr = $this->{passingreason} ? " - ($this->{passingreason}) -" : '' ;
        my $logsub = ( $subjectLogging ? " $subjectStart$this->{originalsubject}$subjectEnd" : '' );
        addSpamProb($fh,0,0);
        $this->{sayMessageOK} = "message ok".de8($pr).$logsub.de8($fn);
        isnotspam($fh,$done);
    }
}
