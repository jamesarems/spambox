#line 1 "sub main::BayesOK_Run"
package main; sub BayesOK_Run {
    my($fh,$msg,$ip)=@_;
    d('BayesOK_Run');
    my $this=$Con{$fh};
    if ($this->{skipBayes}) {
        delete $this->{skipBayes};
        return 1;
    }
    delete $this->{skipBayes};
    return 1 if $lockBayes;
    $this->{prepend}='';
    return 1 if $this->{whitelisted} && ! $BayesWL;
    return 1 if ($this->{noprocessing} & 1) && ! $BayesNP;
    return 1 if $this->{relayok} && ! $BayesLocal;
    $fh = 0 if "$fh" =~ /^\d+$/o;
    if (! $haveSpamdb && !($haveSpamdb = getDBCount('Spamdb','spamdb'))) {
        mlog($fh,"Bayesian is not available - spamdb is empty") if $BayesianLog;
        return 1;
    }
    if ($lockBayes) {
        mlog($fh,"Bayesian is not available - spamdb is still locked by a rebuild task") if $BayesianLog;
        return 1;
    }
    my $DoBayesian = $DoBayesian;    # copy the global to local - using local from this point
    $DoBayesian = $this->{overwritedo} if ($this->{overwritedo});   # overwrite requ by Plugin
    my $stime = time;

    my ($bd,$ok);
    if ($this->{clean}) {
        ($bd,$ok) = ($this->{clean}, 1);
        delete $this->{clean};
    }
    if (! $bd) {
        if ($fh) {
            eval {
              local $SIG{ALRM} = sub { die "__alarm__\n" };
              alarm($BayesMaxProcessTime + 10);
              ($bd,$ok) = &clean($msg);
              alarm(0);
            };
        } else {
            eval{$bd = $$msg;$ok = 1;};
            $msg = \'';
        }
        alarm(0);
        if ($@) {
            if ( $@ =~ /__alarm__/o ) {
                my $itime = time - $stime;
                mlog( $fh, "BayesOK: timed out after $itime secs.", 1 );
            } else {
                mlog( $fh, "BayesOK: failed: $@", 1 );
            }
        }
        unless ($ok) {
            mlog($fh,"info: Bayesian-Process-Timeout ($BayesMaxProcessTime s) is reached - Bayesian Check will only be done on mail header") if ($BayesianLog && time-$stime > $BayesMaxProcessTime);
            my $itime=time-$stime;
            mlog($fh,"info: Bayesian-Check-Conversion has taken $itime seconds") if $BayesianLog >= 2;
            return 1;
        }
    }

    $ip = $this->{cip} if $this->{ispip} && $this->{cip};

    my $msg_is7bit = is_7bit_clean($msg);
    if(!$this->{whitelisted} && $whiteRe && ( $bd=~/($whiteReRE)/ || ($msg_is7bit && $$msg=~/($whiteReRE)/) )) {
        $this->{whitelisted}=1;
        my ($r1,$r2) = ($1,$2);
        mlogRe($fh,($r1||$r2),'whiteRe','whitelisting');
        if (! $BayesWL) {
            $this->{passingreason} = "whiteRe '".($r1||$r2)."'";
            $itime=time-$stime;
            mlog($fh,"info: HMM-Check has taken $itime seconds") if $BayesianLog >= 2;
            $this->{spamprob}=0;
            return 1;
        }
    }

    if ( $BayesLocal &&
         $this->{relayok} &&
         (     ( $noBayesian_local   &&   matchSL($this->{mailfrom},'noBayesian_local')   )
            || ( $Bayesian_localOnly && ! matchSL($this->{mailfrom},'Bayesian_localOnly') )
         )
       )
    {
        mlog($fh,"Bayesian Check skipped for local sender") if $BayesianLog>=2;
        $itime=time-$stime;
        mlog($fh,"info: Bayesian-Check has taken $itime seconds") if $BayesianLog >= 2;
        $this->{spamprob}=0;
        return 1;
    }
    my @rcpt = ($this->{mailfrom},split(/ /o,$this->{rcpt}));
    if ($this->{nobayesian} || ($noBayesian && matchSL(\@rcpt,'noBayesian'))) {
        mlog($fh,"Bayesian Check skipped on noBayesian") if $BayesianLog>=2;
        $itime=time-$stime;
        mlog($fh,"info: Bayesian-Check has taken $itime seconds") if $BayesianLog >= 2;
        $this->{spamprob}=0;
        $this->{nobayesian} = 1;
        return 1;
    }
    if(!($this->{allLoveBaysSpam} & 1) && $baysSpamLoversRe && ($bd=~/($baysSpamLoversReRE)/ || ($msg_is7bit && $$msg=~/($baysSpamLoversReRE)/))) {
        mlogRe($fh,($1||$2),'baysSpamLoversRe','spamlover');
        $this->{allLoveBaysSpam}=1;
    }
    if(!($this->{spamlover} & 1) && $SpamLoversRe && ($bd=~/($SpamLoversReRE)/ || ($msg_is7bit && $$msg=~/($SpamLoversReRE)/))) {
        mlogRe($fh,($1||$2),'SpamLoversRe','spamlover');
        $this->{spamlover}=1;
    }
    my $tlit=&tlit($DoBayesian);

    my ($v,$lt,$t);
    my @t;

    push(@t,$URIBLaddWeight{obfuscatedip}) if $this->{obfuscatedip};
    push(@t,$URIBLaddWeight{obfuscateduri}) if $this->{obfuscateduri};
    push(@t,$URIBLaddWeight{maximumuniqueuri}) if $this->{maximumuniqueuri};
    push(@t,$URIBLaddWeight{maximumuri}) if $this->{maximumuri};

    my $privat;
    ($privat) = lc $this->{rcpt} =~ /(\S+)/o if ! $this->{relayok};
    my ($ar,$ha) = BayesWords(\$bd,$privat);
    push(@t, @$ar); undef $ha;
    $itime=time-$stime; mlog($fh,"info: Bayesian-Check has taken $itime seconds") if $BayesianLog >= 2;
    return 1 if @t < 2 && $t[0] eq '';
    if (@t < 6 && $currentDBVersion{Spamdb} ne $requiredDBVersion{Spamdb}) {
        mlog(0,"warning: the current Spamdb is possibly incompatible to this version of ASSP. Please run a rebuildspamdb. current: $currentDBVersion{Spamdb} - required: $requiredDBVersion{Spamdb}") if ! ($ignoreDBVersionMissMatch & 1);
    }
    (my $p1, my $p2, my $c1, $this->{spamprob}, $this->{spamconf}) = BayesHMMProb(\@t);

    if ($baysConf>0) {
        mlog($fh, sprintf("Bayesian Check $tlit - Prob: %.5f / Confidence: %.5f => %s.%s", $this->{spamprob}, $this->{spamconf}, $this->{spamconf}<$baysConf?"doubtful":"confident", ($this->{spamprob}<$baysProbability)?"ham":"spam"),1) if $BayesianLog || $DoBayesian>=2;
        $this->{bayeslowconf}=1 if ($this->{spamprob}>=$baysProbability && $this->{spamconf}<$baysConf && $DoBayesian == 1);
        if ($enableGraphStats) {
            my $w = ($this->{spamprob}<$baysProbability)?"ham":"spam";
            if ( $this->{spamconf} >= ($baysConf/100) && $this->{spamconf} <= ($baysConf*100) ) {   # collect stat data
                my $conf = sprintf("%.5f",$this->{spamconf});
                ${"bayesconf_$w"}{$conf}++;
            } elsif ($this->{spamconf} > ($baysConf*100)) {
                ${"bayesconf_$w"}{1}++;
            } else {
                ${"bayesconf_$w"}{0}++;
            }
            threads->yield();
        }
    } else {
        mlog($fh, sprintf("Bayesian Check $tlit - Prob: %.5f => %s", $this->{spamprob}, ($this->{spamprob}<$baysProbability)?"ham":"spam"),1) if $BayesianLog || $DoBayesian>=2;
    }

    if (   defined $this->{hmmprob}
        && (    ($this->{hmmprob} >= $baysProbability && $this->{spamprob} < $baysProbability)
             or ($this->{hmmprob} < $baysProbability && $this->{spamprob} >= $baysProbability))
       )
    {
        mlog($fh,sprintf("info: got different spam result for Bayesian and HMM : %.5f - %.5f",$this->{spamprob},$this->{hmmprob})) if $BayesianLog >= 2;
        mlog(0,"warning: the current Spamdb is possibly incompatible to this version of ASSP. Please run a rebuildspamdb. current: $currentDBVersion{Spamdb} - required: $requiredDBVersion{Spamdb}") if $currentDBVersion{Spamdb} ne $requiredDBVersion{Spamdb} && ! ($ignoreDBVersionMissMatch & 1);
    }

    return 1 if $DoBayesian==2;
    $this->{messagereason}=sprintf("Bayesian Probability: %.5f", $this->{spamprob});
    if ($this->{spamprob} >= $baysProbability)  {
        my @valence = (0 , 0);
        $valence[0] = ($this->{relayok}) ? ${'bayslocalValencePB'}[0] : ${'baysValencePB'}[0];
        $valence[0] = int($valence[0] * $this->{spamprob} + 0.5);
        $valence[0] = int(($baysConf && $baysConfidenceHalfScore && $this->{spamconf} < $baysConf) ? $valence[0] * $this->{spamprob} / 2 + 0.5 : $this->{spamprob} * $valence[0] + 0.5);
        $valence[1] = ($this->{relayok}) ? ${'bayslocalValencePB'}[1] : ${'baysValencePB'}[1];
        $valence[1] = int($valence[1] * $this->{spamprob} + 0.5);
        $valence[1] = int(($baysConf && $baysConfidenceHalfScore && $this->{spamconf} < $baysConf) ? $valence[1] * $this->{spamprob} / 2 + 0.5 : $this->{spamprob} * $valence[1] + 0.5);
        pbAdd($fh,$this->{ip},\@valence,"Bayesian") if max(@valence) > 0 && $fh;
    } elsif ($this->{spamprob} >= 1 - $baysProbability) {
        my @valence = (0 , 0);
        $valence[0] = ($this->{relayok}) ? ${'bayslocalValencePB'}[0] / 2 : ${'baysValencePB'}[0] / 2;
        $valence[0] = int($valence[0] * $this->{spamprob} + 0.5);
        $valence[0] = int(($baysConf && $baysConfidenceHalfScore && $this->{spamconf} < $baysConf) ? $valence[0] * $this->{spamprob} / 2 + 0.5 : $this->{spamprob} * $valence[0] + 0.5);
        $valence[1] = ($this->{relayok}) ? ${'bayslocalValencePB'}[1] / 2 : ${'baysValencePB'}[1] / 2;
        $valence[1] = int($valence[1] * $this->{spamprob} + 0.5);
        $valence[1] = int(($baysConf && $baysConfidenceHalfScore && $this->{spamconf} < $baysConf) ? $valence[1] * $this->{spamprob} / 2 + 0.5 : $this->{spamprob} * $valence[1] + 0.5);
        if (max(@valence) > 0) {
            mlog($fh,sprintf("Bayesian Check $tlit - Prob: %.5f shows an 'unsure' state - doing only message scoring - calculating half scores", $this->{spamprob}),1) if $BayesianLog;
            mlog(0,"warning: the current Spamdb is possibly incompatible to this version of ASSP. Please run a rebuildspamdb. current: $currentDBVersion{Spamdb} - required: $requiredDBVersion{Spamdb}") if $currentDBVersion{Spamdb} ne $requiredDBVersion{Spamdb} && ! ($ignoreDBVersionMissMatch & 1);
            pbAdd($fh,$this->{ip},\@valence,"Bayesian",1) if $fh;
        }
    } elsif (($baysConf && $this->{spamconf} >= $baysConf) || ! $baysConf) {
        my @valence = (0 , 0);
        $valence[0] = ${'bayshamValencePB'}[0];
        $valence[0] = int($valence[0] * (1 - $this->{spamprob}));
        $valence[1] = ${'bayshamValencePB'}[1];
        $valence[1] = int($valence[1] * (1 - $this->{spamprob}));
        for (@valence) {$_= -1*$_ if $_ > 0;}
        if (min(@valence) < 0) {
            mlog($fh,sprintf("Bayesian Check $tlit - Prob: %.5f shows a confident 'HAM' state - Bonus", $this->{spamprob}),1) if $BayesianLog;
            pbAdd($fh,$this->{ip},\@valence,"Bayesian-HAM",1) if $fh;
        }
    }
    return 1 if $DoBayesian==3;
    return $this->{spamprob}<$baysProbability;
}
