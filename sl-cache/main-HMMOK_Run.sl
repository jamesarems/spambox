#line 1 "sub main::HMMOK_Run"
package main; sub HMMOK_Run {
    my($fh,$msg)=@_;
    my $this = $Con{$fh};
    d('HMMOK_Run');
    delete $this->{hmmprob};
    $this->{prepend}='';
    $fh = 0 if "$fh" =~ /^\d+$/o;
    return 1 if $this->{whitelisted} && ! $BayesWL;
    return 1 if ($this->{noprocessing} & 1) && ! $BayesNP;
    return 1 if $this->{relayok} && ! $BayesLocal;
    if ($lockHMM) {
        mlog($fh,"HMM is not available - hmmdb is still locked by a rebuild task") if $BayesianLog;
        return 1;
    }
    if (! $haveHMM && !($haveHMM = getDBCount('HMMdb','spamdb'))) {
        mlog($fh,"HMM is not available - hmmdb is empty") if $BayesianLog;
        return 1;
    }
    %{$this->{hmmValues}} = () unless $fh;
    my $DoHMM = $DoHMM;    # copy the global to local - using local from this point
    $DoHMM = $this->{overwritedo} if ($this->{overwritedo});   # overwrite requ by Plugin
    my $stime = time;

    my ($bd,$ok);
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
            mlog( $fh, "HMMOK: timed out after $itime secs.", 1 );
        } else {
            mlog( $fh, "HMMOK: failed: $@", 1 );
        }
    }
    unless ($ok) {
        mlog($fh,"info: HMM-Process-Timeout ($BayesMaxProcessTime s) is reached - HMM Check will only be done on mail header") if ($BayesianLog && time-$stime > $BayesMaxProcessTime);
        my $itime=time-$stime;
        mlog($fh,"info: HMM-Check-Conversion has taken $itime seconds") if $BayesianLog >= 2;
        return 1;
    }

    my $msg_is7bit = is_7bit_clean($msg);
    if(!$this->{whitelisted} && $whiteRe && ( $bd=~/($whiteReRE)/ || ($msg_is7bit && $$msg=~/($whiteReRE)/) )) {
        $this->{whitelisted}=1;
        my ($r1,$r2) = ($1,$2);
        mlogRe($fh,($r1||$r2),'whiteRe','whitelisting');
        if (! $BayesWL) {
            $this->{passingreason} = "whiteRe '".($r1||$r2)."'";
            $itime=time-$stime;
            mlog($fh,"info: HMM-Check has taken $itime seconds") if $BayesianLog >= 2;
            $this->{bayesdone} = 1;
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
        mlog($fh,"HMM-Check skipped for local sender") if $BayesianLog>=2;
        $itime=time-$stime;
        mlog($fh,"info: HMM-Check has taken $itime seconds") if $BayesianLog >= 2;
        $this->{bayesdone} = 1;
        return 1;
    }
    my @rcpt = ($this->{mailfrom},split(/ /o,$this->{rcpt}));
    if ($this->{nobayesian} || ($noBayesian && matchSL(\@rcpt,'noBayesian'))) {
        mlog($fh,"HMM Check skipped on noBayesian") if $BayesianLog>=2;
        $itime=time-$stime;
        mlog($fh,"info: HMM-Check has taken $itime seconds") if $BayesianLog >= 2;
        $this->{bayesdone} = $this->{nobayesian} = 1;
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

    $this->{clean} = $bd unless exists $this->{hmmValues};

    my $tlit=&tlit($DoHMM);

    my @words;
    my @t;
    $this->{hmmres} = 0;

    push(@t,$URIBLaddWeight{obfuscatedip}) if $this->{obfuscatedip};
    push(@t,$URIBLaddWeight{obfuscateduri}) if $this->{obfuscateduri};
    push(@t,$URIBLaddWeight{maximumuniqueuri}) if $this->{maximumuniqueuri};
    push(@t,$URIBLaddWeight{maximumuri}) if $this->{maximumuri};

    my $privat;
    ($privat) = $this->{rcpt} =~ /(\S*)/o if ! $this->{relayok};
    my $domain = (eval('defined ${chr(ord(",") << ($DoPrivatSpamdb > 1))};')) ? lc $privat : '';
    $privat = (eval('defined ${chr(ord(",") << ($DoPrivatSpamdb & 1))};')) ? lc $privat : '';
    $domain =~ s/^[^\@]*\@/\@/o;
    @HmmBayWords = ();
    my %seen;
    keys %seen = 1024;
    use re 'eval';
    local $^R;
    while (eval {$bd =~ /([$BayesCont]{2,})(?{$1})/go}) {
        my @Words;
        (@Words = BayesWordClean($^R)) or next;
        push @HmmBayWords, @Words if $DoBayesian;
        while (my $t = shift @Words) {
            next if length($t) > 37;
            push @words, $t;
            if (@words > $HMMSequenceLength) {
                shift @words if @words > $HMMSequenceLength + 1;
                my $sym = join($;,@words);
                next if (++$seen{$sym} > 2);
                my $res;
                if ($privat && ($res = $HMMdb{$privat.$;.$sym})) {
                    for (1...$BayesPrivatPrior) {push @t,$res;$this->{hmmres}++;}
                    ${$this->{hmmValues}}{'private: '.join(' ', @words)} = $res if exists $this->{hmmValues};
                    next;
                }
                if ($domain && ($res = $HMMdb{$domain.$;.$sym})) {
                    for (1...$BayesDomainPrior) {push @t,$res;$this->{hmmres}++;}
                    ${$this->{hmmValues}}{'domain: '.join(' ', @words)} = $res if exists $this->{hmmValues};
                    next;
                }
                next unless ($res = $HMMdb{$sym});
                push @t,$res;
                $this->{hmmres}++;
                ${$this->{hmmValues}}{join(' ', @words)} = $res if exists $this->{hmmValues};
            }
        }
    }
    my $skipBonus;
    if ($this->{hmmres} < int($maxBayesValues / 12 + 1)) {
        mlog(0,"warning: the current HMMdb is possibly incompatible to this version of ASSP. Please run a rebuildspamdb. current: $currentDBVersion{HMMdb} - required: $requiredDBVersion{HMMdb}") if ($currentDBVersion{HMMdb} ne $requiredDBVersion{HMMdb} && ! ($ignoreDBVersionMissMatch & 2));
        mlog($fh,'HMM-Check has given less than '.int($maxBayesValues / 12 + 1).' results - using monitoring mode only');
        $DoHMM = 2;
        $tlit=&tlit($DoHMM);
        $this->{prepend}="[HMM]";
        $this->{prepend}.="$tlit" if $DoHMM>=2;
        $skipBonus = 1;
    } elsif ($this->{hmmres} < int($maxBayesValues / 3 + 1) && $DoHMM == 1) {
        mlog(0,"warning: the current HMMdb is possibly incompatible to this version of ASSP. Please run a rebuildspamdb. current: $currentDBVersion{HMMdb} - required: $requiredDBVersion{HMMdb}") if ($currentDBVersion{HMMdb} ne $requiredDBVersion{HMMdb} && ! ($ignoreDBVersionMissMatch & 2));
        mlog($fh,'HMM-Check has given less than '.int($maxBayesValues / 3 + 1).' results - using soring mode only');
        $DoHMM = 3;
        $tlit=&tlit($DoHMM);
        $this->{prepend}="[HMM]";
        $this->{prepend}.="$tlit" if $DoHMM>=2;
        $skipBonus = 1;
    }

    $itime=time-$stime;
    mlog($fh,"info: HMM-Check has taken $itime seconds and has given $this->{hmmres} results") if $BayesianLog >= 2;
    return 1 unless $this->{hmmres};
    (my $p1, my $p2, my $c1, $this->{hmmprob}, $this->{hmmconf}) = BayesHMMProb(\@t);

    if ($baysConf>0) {
        mlog($fh, sprintf("HMM Check $tlit - Prob: %.5f / Confidence: %.5f => %s.%s", $this->{hmmprob}, $this->{hmmconf}, $this->{hmmconf}<$baysConf?"doubtful":"confident", ($this->{hmmprob}<$baysProbability)?"ham":"spam"),1) if $BayesianLog || $DoHMM>=2;
        $this->{bayeslowconf}=1 if ($this->{hmmprob}>=$baysProbability && $this->{hmmconf}<$baysConf && $DoHMM == 1);
        if ($enableGraphStats) {
            my $w = ($this->{hmmprob}<$baysProbability)?"ham":"spam";
            if ( $this->{hmmconf} >= ($baysConf/100) && $this->{hmmconf} <= ($baysConf*100) ) {    # collect stat data
                my $conf = sprintf("%.5f",$this->{hmmconf});
                ${"hmmconf_$w"}{$conf}++;
            } elsif ($this->{hmmconf} > ($baysConf*100)) {
                ${"hmmconf_$w"}{1}++;
            } else {
                ${"hmmconf_$w"}{0}++;
            }
            threads->yield();
        }
    } else {
        mlog($fh, sprintf("HMM Check $tlit - Prob: %.5f => %s", $this->{hmmprob}, ($this->{hmmprob}<$baysProbability)?"ham":"spam"),1) if $BayesianLog || $DoHMM>=2;
    }
    return 1 if $DoHMM == 2;
    $this->{messagereason} = sprintf("HMM Probability: %.5f", $this->{hmmprob});
    if ($DoBayesian && $BayesAfterHMM) {
        my ($lp,$hp) = split(/[^\d\.]+/o,$BayesAfterHMM,2);
        $lp = $lp + 0;
        $hp = $hp + 0;
        if ( !($lp && $hp) ){
            ($lp,$hp) = (( 1 - $baysProbability ),$baysProbability);
            mlog($fh,"ERROR: invalid value for 'BayesAfterHMM' found ('$BayesAfterHMM') - the value is now set to '$lp-$hp'");
            threads->yield();
            $BayesAfterHMM = $Config{BayesAfterHMM} = "$lp-$hp";
            threads->yield();
        }
        ($lp,$hp) = ($hp,$lp) if $lp > $hp;
        if ($this->{hmmprob} <= $lp || $this->{hmmprob} >= $hp) {
            if ($baysConf) {
                if ($this->{hmmconf} < $baysConf) {
                    mlog($fh,"Bayesian check will run ( BayesAfterHMM $BayesAfterHMM - but low confidence ) - $this->{messagereason}") if $BayesianLog > 1 && $fh;
                } else {
                    $this->{skipBayes} = 1;
                    mlog($fh,"Bayesian check will be skipped ( high confidence and BayesAfterHMM $BayesAfterHMM ) - $this->{messagereason}") if $BayesianLog > 1 && $fh;
                }
            } else {
                $this->{skipBayes} = 1;
                mlog($fh,"Bayesian check will be skipped ( BayesAfterHMM $BayesAfterHMM ) - $this->{messagereason}") if $BayesianLog > 1 && $fh;
            }
        } else {
            mlog($fh,"Bayesian check will run ( BayesAfterHMM $BayesAfterHMM ) - $this->{messagereason}") if $BayesianLog > 1 && $fh;
        }
    }
    if ($this->{hmmprob}>=$baysProbability)  {
        my @valence = (0 , 0);
        $valence[0] = ($this->{relayok}) ? ${'HMMlocalValencePB'}[0] : ${'HMMValencePB'}[0];
        $valence[0] = int($valence[0] * $this->{hmmprob} + 0.5);
        $valence[0] = int(($baysConf && $baysConfidenceHalfScore && $this->{hmmconf}<$baysConf) ? $valence[0] * $this->{hmmprob} / 2 + 0.5 :$valence[0] * $this->{hmmprob} + 0.5);
        $valence[1] = ($this->{relayok}) ? ${'HMMlocalValencePB'}[1] : ${'HMMValencePB'}[1];
        $valence[1] = int($valence[1] * $this->{hmmprob} + 0.5);
        $valence[1] = int(($baysConf && $baysConfidenceHalfScore && $this->{hmmconf}<$baysConf) ? $valence[1] * $this->{hmmprob} / 2 + 0.5 :$valence[1] * $this->{hmmprob} + 0.5);
        pbAdd($fh,$this->{ip},\@valence,"HMM") if max(@valence) > 0 && $fh;
    } elsif ($this->{hmmprob} >= 1 - $baysProbability) {
        my @valence = (0 , 0);
        $valence[0] = ($this->{relayok}) ? ${'HMMlocalValencePB'}[0] / 2 : ${'HMMValencePB'}[0] / 2;
        $valence[0] = int($valence[0] * $this->{hmmprob} + 0.5);
        $valence[0] = int(($baysConf && $baysConfidenceHalfScore && $this->{hmmconf} < $baysConf) ? $valence[0] * $this->{hmmprob} / 2 + 0.5 : $this->{hmmprob} * $valence[0] + 0.5);
        $valence[1] = ($this->{relayok}) ? ${'HMMlocalValencePB'}[1] / 2 : ${'HMMValencePB'}[1] / 2;
        $valence[1] = int($valence[1] * $this->{hmmprob} + 0.5);
        $valence[1] = int(($baysConf && $baysConfidenceHalfScore && $this->{hmmconf} < $baysConf) ? $valence[1] * $this->{hmmprob} / 2 + 0.5 : $this->{hmmprob} * $valence[1] + 0.5);
        if (max(@valence) > 0) {
            mlog($fh,sprintf("HMM Check $tlit - Prob: %.5f shows an 'unsure' state - doing only message scoring - calculating half scores", $this->{hmmprob}),1) if $BayesianLog;
            pbAdd($fh,$this->{ip},\@valence,"HMM",1) if $fh;
        }
    } elsif (! $skipBonus) {
        my @valence = (0 , 0);
        $valence[0] = ${'HMMhamValencePB'}[0];
        $valence[0] = int($valence[0] * (1 - $this->{hmmprob}));
        $valence[1] = ${'HMMhamValencePB'}[1];
        $valence[1] = int($valence[1] * (1 - $this->{hmmprob}));
        for (@valence) {$_= -1*$_ if $_ > 0;}
        if (min(@valence) < 0) {
            mlog($fh,sprintf("HMM Check $tlit - Prob: %.5f shows a confident 'HAM' state - Bonus", $this->{hmmprob}),1) if $BayesianLog;
            pbAdd($fh,$this->{ip},\@valence,"HMM-HAM",1) if $fh;
        }
    }
    return 1 if $DoHMM==3;
    return $this->{hmmprob}<$baysProbability;
}
