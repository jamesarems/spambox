#line 1 "sub main::TestMessageScore"
package main; sub TestMessageScore {
    my $fh = shift;
    my $this = $Con{$fh};
    &NewSMTPConCall();
    delete $this->{messagereason};
    
    return 0 if $this->{messagescoredone};
    return 0 if ($MsgScoreOnEnd && ! $this->{TestMessageScore});

    my $DoPenaltyMessage = $DoPenaltyMessage;
    my $PenaltyMessageLimit = defined $this->{spamMaxScore} ? $this->{spamMaxScore} : $PenaltyMessageLimit;
    if ($this->{relayok}) {
        $DoPenaltyMessage = $DoLocalPenaltyMessage;
        $PenaltyMessageLimit = defined $this->{spamMaxScore} ? $this->{spamMaxScore} : $LocalPenaltyMessageLimit;
    }
    $PenaltyMessageLimit ||= 1;
    if ( $DoPenaltyMessage && $PenaltyMessageLimit
        && $this->{messagescore} >= $PenaltyMessageLimit )
    {
       delete $this->{messagelow};
       return 1;
    }
    return 0;
}
