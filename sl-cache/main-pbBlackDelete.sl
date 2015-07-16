#line 1 "sub main::pbBlackDelete"
package main; sub pbBlackDelete {
    my($fh,$myip)=@_;
    return if !$DoPenalty;
    my $this=$Con{$fh};
    $myip = $this->{cip} if $this->{ispip} && $this->{cip} && $myip eq $this->{ip};
    my $ip=&ipNetwork($myip, $PenaltyUseNetblocks );
    mlog(0,"PB: deleting(black) $myip",1) if $PenaltyLog>=2 && exists $PBBlack{$ip};
    delete $PBBlack{$myip};
    if ($ip ne $myip) {
        delete $PBBlack{$ip};
    }
}
