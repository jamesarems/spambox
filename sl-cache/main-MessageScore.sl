#line 1 "sub main::MessageScore"
package main; sub MessageScore {
    my($fh,$done)=@_;
    my $DoPenaltyMessage = $DoPenaltyMessage;
    my $PenaltyMessageLimit = $PenaltyMessageLimit;
    if ($Con{$fh}->{relayok}) {
        $DoPenaltyMessage = $DoLocalPenaltyMessage;
        $PenaltyMessageLimit = $LocalPenaltyMessageLimit;
    }
    return if ! $DoPenaltyMessage;
    return if ! $PenaltyMessageLimit;
    return MessageScore_Run($fh,$done);
}
