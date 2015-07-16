#line 1 "sub main::PBOK_Run"
package main; sub PBOK_Run {
    my($fh,$myip) = @_;
    my $this=$Con{$fh};
    $myip = $this->{cip} if $this->{ispip} && $this->{cip};
    d('PBOK');
    return 1 if $this->{PBOK};
    $this->{PBOK} = 1;
    $this->{prepend}='';
    skipCheck($this,'ro','wl','co','nb','ispcip') && return 1;
    return 1 if ($this->{noprocessing} & 1);
    return 1 if (($this->{rwlok} && ! $this->{cip}) or ($this->{cip} && pbWhiteFind($this->{cip})));

    #return 1 if $this->{contentonly};
    return 1 if (pbWhiteFind($myip));
    my $ip = &ipNetwork($myip, $PenaltyUseNetblocks );
    return 1 if (! pbBlackFind($myip));
    my($ct,$ut,$level,$totalscore,$sip,$reason)=split(/\s+/o,$PBBlack{$ip});
    $this->{messagereason}="totalscore for $myip is $totalscore, last bad penalty was '$reason'";
    return 1 if $totalscore<$PenaltyLimit;
    $this->{prepend}='[PenaltyBox]';

    if ($DoPenalty == 2 || $DoPenalty == 3) {
        mlog( $fh, "[monitoring] $this->{messagereason}" );
        return 1;
    }
    return 0;
}
