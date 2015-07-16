#line 1 "sub main::MessageScorePL"
package main; sub MessageScorePL {
    my($fh,@plres)=@_;
    my $DoPenaltyMessage = $DoPenaltyMessage;
    my $PenaltyMessageLimit = $PenaltyMessageLimit;
    if ($Con{$fh}->{relayok}) {
        $DoPenaltyMessage = $DoLocalPenaltyMessage;
        $PenaltyMessageLimit = $LocalPenaltyMessageLimit;
    }
    return @plres if !$DoPenaltyMessage;
    return @plres if !$PenaltyMessageLimit;
    return MessageScorePL_Run($fh,@plres);
}
