#line 1 "sub main::MessageScore_Run"
package main; sub MessageScore_Run {
    my($fh,$done)=@_;
    my $this=$Con{$fh};
    return 1 if $this->{messagescoredone};
    $this->{messagescoredone} = 1;
    my $PenaltyMessageLimit = defined $this->{spamMaxScore} ? $this->{spamMaxScore} : $this->{relayok} ? $LocalPenaltyMessageLimit : $PenaltyMessageLimit;
    $this->{messagereason}="MessageScore $this->{messagescore}, limit $PenaltyMessageLimit" ;
    my $slok=$this->{allLovePBSpam}==1;
    my $er = $SpamError;
    my $DoPenaltyMessage = $this->{relayok} ? $DoLocalPenaltyMessage : $DoPenaltyMessage;
    $er = $PenaltyError if $PenaltyError;
    $this->{prepend}="[MessageLimit]";
    $this->{prepend}="[MessageLimit][monitoring]" if $DoPenaltyMessage == 2;
    $this->{prepend} = "[MessageLimit][tagging]" if $DoPenaltyMessage == 4;
    delayWhiteExpire($fh) if $DoPenaltyMessage != 2;
    mlog($fh,"monitoring ($this->{messagereason})",1) if $DoPenaltyMessage == 2;
    $Stats{msgscoring}++ if ($DoPenaltyMessage == 1 || $DoPenaltyMessage == 4);
    $this->{tagmode} = 1 if $DoPenaltyMessage == 4;
    thisIsSpam($fh,$this->{messagereason},$spamMSLog,$er,$msTestMode,$slok,
               ($slok || $done)) if $DoPenaltyMessage == 1 || $DoPenaltyMessage == 4;
}
