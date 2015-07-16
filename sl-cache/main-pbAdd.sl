#line 1 "sub main::pbAdd"
package main; sub pbAdd {

    # status:
    # 0-message score and pbblackadd
    # 1-message score but don't pbblackadd
    # 2-pbblackadd but don't message score
    # noheader:
    # 0-write X-Assp header info
    # 1-skip X-Assp header info
    my($fh,$myip,$score,$reason,$status,$noheader)=@_;
    return unless $fh;
    return unless $myip;
    my $this = $Con{$fh};
    return if $this->{relayok} && ! $DoLocalPenaltyMessage;
    my @score;
    if ($score =~ /ValencePB$/o) {
       defined ${chr(ord(",") << 1)} and (@score = @{$score});
    } elsif (ref($score) eq 'ARRAY') {
       defined ${chr(ord(",") << 1)} and (@score = @{$score});
    } elsif ($score = 0+$score) {
       push @score, $score, $score;
    } else {
       return;
    }
    return if $status && ! $score[$status - 1];
    return if ! $status && ! max(@score);
    $myip = $this->{cip} if $this->{ispip} && $this->{cip} && $myip eq $this->{ip};
    my $reason2=$reason;
    $reason2=$this->{messagereason} if $this->{messagereason};
    if ( ! $noheader ) {
        $this->{myheader}.="X-Assp-Message-Score: $score[0] ($reason2)\r\n" if $AddScoringHeader && $status < 2 && $score[0];
        $this->{myheader}.="X-Assp-IP-Score: $score[1] ($reason2)\r\n" if $AddScoringHeader && $status != 1 && $score[1];
    }
    $this->{messagescore} = 0 unless $this->{messagescore};
    if ($score[0] && $status != 2) {
        $this->{messagescore} += $score[0];
        my $added = $score =~ /ValencePB$/o ? "$score[0] ($score)" : $score[0];
        mlog($fh,"Message-Score: added $added for $reason2, total score for this message is now $this->{messagescore}",1) if ($MessageLog || $PenaltyLog>=2);
        my $sr = $reason;
        $sr =~ s/\s*:.*$//os;
        $sr =~ s/^\s+//o;
        lock(%ScoreStats) if is_shared(%ScoreStats);
        $ScoreStats{$sr}++;
#        printScoreStats($sr,$ScoreStats{$sr});
    } elsif ($score[1] && $status == 2) {
        my $sr = $reason;
        $sr =~ s/\s*:.*$//os;
        $sr =~ s/^\s+//o;
        lock(%ScoreStats) if is_shared(%ScoreStats);
        $ScoreStats{$sr}++;
    }

    return if $this->{relayok};
    return if ($status == 1);
    return unless $score[1];
    return if !$DoPenalty;
    return if ($this->{isbounce} && $DoNotPenalizeNull);
    return if ($this->{red} && $DoNotPenalizeRed);
    return if $this->{ispip} && ! $this->{cip};
    return if ! $PBscoreNoDelay && $this->{nodelay} && ! $this->{ispip};
    return if ($myip =~ /$IPprivate/o);
    return if ! $PBscoreNoDelay && $this->{cip} && matchIP($this->{cip},'noDelay',$fh,1 );
    return if ($this->{nopb} || ($this->{nopb} = matchIP($myip,'noPB',$fh,1 )));
    return if $this->{pbwhite} || pbWhiteFind($myip);
    pbBlackAdd($fh,$myip,$score[1],$reason);
}
