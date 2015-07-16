#line 1 "sub main::NumRcptOK_Run"
package main; sub NumRcptOK_Run {
    my($fh,$block)=@_;
    my $this=$Con{$fh};
    d('NumRcptOK');
    my $DoMaxDupRcpt = $DoMaxDupRcpt;
    $DoMaxDupRcpt = 3 if !$block  && $DoMaxDupRcpt == 1;
    return 1 unless $this->{numrcpt};
    return 1 unless (scalar keys %{$this->{rcptlist}});
    skipCheck($this,'aa','ro','wl') && return 1;
    return 1 if ($this->{noprocessing} & 1);
    return 1 if ($this->{spamlover} & 1);
    return 1 if ((scalar keys %{$this->{rcptlist}}) + $MaxDupRcpt >= $this->{numrcpt});
    my $maxRcpt;
    my $maxNum = 0;
    while (my ($k,$v) = each %{$this->{rcptlist}}) {
        my $tt = needEs($v,' time','s');
        mlog($fh,"info: address $k used $tt") if $ValidateUserLog >= 2;
        if ($v > $maxNum) {
            $maxNum = $v;
            $maxRcpt = $k;
        }
    }
    my $tlit = &tlit($DoMaxDupRcpt);
    $this->{prepend}="[MaxDuplicateRcpt]";
    $this->{messagereason} = "too many duplicate recipients ($maxRcpt , $maxNum)";
    mlog($fh,"$tlit $this->{messagereason}",1) if $ValidateUserLog;
    return 1 if $DoMaxDupRcpt == 2;
    my $reply = "550 5.5.3 $this->{messagereason}";
    pbAdd( $fh, $this->{ip}, 'mdrValencePB', 'MaxDuplicateRcpt' );
    return 1 if $DoMaxDupRcpt == 3;
    $Stats{rcptNonexistent}++;
    seterror($fh, $reply,1);
    return 0;
}
