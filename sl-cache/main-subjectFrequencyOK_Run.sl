#line 1 "sub main::subjectFrequencyOK_Run"
package main; sub subjectFrequencyOK_Run {
    my $fh = shift;
    my $this=$Con{$fh};
    d('subjectFrequency');

    return 1 unless $this->{subject3};
    skipCheck($this,'ro','wl','np','co','nbip','ispip') && return 1;
    my $mf = &batv_remove_tag(0,$this->{mailfrom},'');
    my $ip = $this->{ip};
    $ip = $this->{cip} if $this->{ispip} && $this->{cip};
    return 1 if ($subjectFrequencyOnly && ! &matchSL($mf,'subjectFrequencyOnly'));
    return 1 if (&matchSL($mf,'NoSubjectFrequency'));
    return 1 if (&matchIP($ip,'NoSubjectFrequencyIP',$fh, 1));

    my $sub = lc($this->{subject3});
    my @subWords;
    $sub = eval{&SPAMBOX_WordStem::process($sub) if ($CanUseSPAMBOX_WordStem);} || $sub;
    @HmmBayWords = ();
    use re 'eval';
    local $^R;
    while (eval {$sub =~ /([$BayesCont]{2,})(?{$1})/go}) {
        my @Words;
        (@Words = BayesWordClean($^R)) or next;
        push @subWords,@Words;
    }
    push @subWords,$sub unless @subWords;
    $sub = join(' ',@subWords);
    my $subjcount;

    my $time = Time::HiRes::time;
    my $data;

    my %F = split(/ /o,$subjectFrequencyCache{$sub});
    my %ips;
    $ips{$ip} = 1;
    foreach (sort keys %F) {
        if ($_ + $subjectFrequencyInt  < $time) {
            delete $F{$_};
            next;
        } else {
            $subjcount++;
            $ips{$F{$_}}++;
        }
    }
    foreach (sort keys %F) {
        $data .= "$_ $F{$_} ";
    }
    $subjectFrequencyCache{$sub} = $data . "$time $ip";
    $subjcount++;
    return 1 if $subjcount < $subjectFrequencyNumSubj;

    my $tlit = &tlit($DoSameSubject);
    $tlit = '[testmode]'  if $allTestMode && $DoSameSubject == 1 || $DoSameSubject == 4;
    my $DoSameSubject = $DoSameSubject;
    $DoSameSubject = 3 if $allTestMode && $DoSameSubject == 1 || $DoSameSubject == 4;

    $this->{prepend} = "[SameSubject]";
    $this->{messagereason} = "passed limit($subjectFrequencyNumSubj) of same subjects in $subjectFrequencyInt seconds";

    mlog( $fh, "$tlit $this->{messagereason}") if $SessionLog;

    pbAdd( $fh, $ip, 'isValencePB', 'LimitingSameSubject' ) if $DoSameSubject != 2;
    if ( $DoSameSubject == 1 ) {
        $Stats{smtpSameSubject}++;
        unless (($send250OKISP && $this->{ispip}) || $send250OK) {
            seterror( $fh, "554 5.7.1 too many mails with same subject", 1 );
            return 0;
        }
    }

    return 1;
}
