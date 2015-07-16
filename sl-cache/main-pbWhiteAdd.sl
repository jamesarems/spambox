#line 1 "sub main::pbWhiteAdd"
package main; sub pbWhiteAdd {
    my($fh,$myip,$reason)=@_;
    $reason =~ s/\s+/_/go;
    my $this=$Con{$fh};
    $myip = $this->{cip} if $this->{ispip} && $this->{cip} && $myip eq $this->{ip};
    my $t = time;
    my $ct = $t;
    my $status = 2;
    my $ut;
    $this->{rwlok}=1;
    return if $this->{isbounce};
    return if $this->{ispip} && !$this->{cip};
    my $ip = &ipNetwork($myip, $PenaltyUseNetblocks);
    lock($PBWhiteLock) if $lockDatabases;
    if ( $this->{nopbwhite} || matchIP( $myip, 'noPBwhite', 0, 1 )) {
        $this->{nopbwhite} = 1;
        delete $PBWhite{$myip};
        if ($ip ne $myip) {
            delete $PBWhite{$ip};
        }
        return;
    }
    pbBlackDelete($fh,$myip);
    my $PBWhite_ip = $PBWhite{$ip};
    my ($s,$r);
    ($ct,$ut,$s,$r)=split(/\s+/o,$PBWhite_ip) if ($PBWhite_ip);
    my $data="$ct $t $status $reason";
    $ip=&ipNetwork($myip,1);
    $PBWhite{$myip}=$data;
    $PBWhite{$ip}=$data;
}
