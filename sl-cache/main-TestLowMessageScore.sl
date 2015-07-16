#line 1 "sub main::TestLowMessageScore"
package main; sub TestLowMessageScore {
    my $fh = shift;
    my $this = $Con{$fh};
    &NewSMTPConCall();
    
    skipCheck($this,'wl') && return 0;
    return 0 if ($this->{noprocessing} & 1);
    my $DoPenaltyMessage = $DoPenaltyMessage;
    my $PenaltyMessageLow = $PenaltyMessageLow;
    if (defined $this->{spamMaxScore} && $this->{spamMaxScore} != $PenaltyMessageLimit) {
        $PenaltyMessageLow = $this->{spamMaxScore} - ($PenaltyMessageLimit - $PenaltyMessageLow);
    }
    my $PenaltyMessageLimit = defined $this->{spamMaxScore} ? $this->{spamMaxScore} : $PenaltyMessageLimit;
    if ($this->{relayok}) {
        $DoPenaltyMessage = $DoLocalPenaltyMessage;
        $PenaltyMessageLow = $LocalPenaltyMessageLow;
        if (defined $this->{spamMaxScore} && $this->{spamMaxScore} != $LocalPenaltyMessageLimit) {
            $PenaltyMessageLow = $this->{spamMaxScore} - ($LocalPenaltyMessageLimit - $LocalPenaltyMessageLow);
        }
        $PenaltyMessageLimit = defined $this->{spamMaxScore} ? $this->{spamMaxScore} : $LocalPenaltyMessageLimit;
    }
    $PenaltyMessageLow = 0 if $PenaltyMessageLow < 0;
    return 1 if ( $DoPenaltyMessage && $PenaltyMessageLow && $PenaltyMessageLimit
        && $this->{messagescore} >= $PenaltyMessageLow && $this->{messagescore} < $PenaltyMessageLimit );

    return 0;
}
