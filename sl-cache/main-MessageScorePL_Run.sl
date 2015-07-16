#line 1 "sub main::MessageScorePL_Run"
package main; sub MessageScorePL_Run {
    my($fh,@plres)=@_;
    my $this=$Con{$fh};
    my $DoPenaltyMessage = $this->{relayok} ? $DoLocalPenaltyMessage : $DoPenaltyMessage;
    my $PenaltyMessageLimit = defined $this->{spamMaxScore} ? $this->{spamMaxScore} : $this->{relayok} ? $LocalPenaltyMessageLimit : $PenaltyMessageLimit;
    $PenaltyMessageLimit ||= 1;
    d("MessageScorePL - score: $this->{messagescore} - limit: $PenaltyMessageLimit");
    return @plres if ($this->{messagescore} < $PenaltyMessageLimit);

    $this->{messagereason}="MessageScore $this->{messagescore}, limit $PenaltyMessageLimit" ;
    my $slok=$this->{allLovePBSpam}==1;
    my $er = $SpamError;
    $er = $PenaltyError if $PenaltyError;
    $this->{prepend}="[MessageLimit]";
    $this->{prepend}="[MessageLimit][monitoring]" if $DoPenaltyMessage == 2;
    delayWhiteExpire($fh) if $DoPenaltyMessage != 2;
    mlog($fh,"monitoring ($this->{messagereason})") if $DoPenaltyMessage == 2;
    $this->{tagmode} = 1 if $DoPenaltyMessage == 4;
    if ($DoPenaltyMessage == 1) {$Stats{msgscoring}++;}

    # @plres = [0]result,[1]data,[2]reason,[3]plLogTo,[4]reply,[5]pltest,[6]pl
    $plres[0] = $msTestMode || $slok;
    $plres[2] = $this->{messagereason};
    $plres[3] = $spamMSLog;
    $plres[4] = $er;
    $plres[5] = $msTestMode;
    return @plres;
}
