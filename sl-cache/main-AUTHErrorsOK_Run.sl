#line 1 "sub main::AUTHErrorsOK_Run"
package main; sub AUTHErrorsOK_Run {
    my $fh = shift;
    my $this = $Con{$fh};
    skipCheck($this,'ro','wl','nbip','ispip') && return 1;
    return 1 if ($this->{noprocessing} & 1);
    return 1 if matchIP($this->{ip},'noMaxAUTHErrorIPs',0,0);
    return 1 if matchIP($this->{ip},'noBlockingIPs', 0, 1);
    my $ip = &ipNetwork( $this->{ip}, 1);
    
    return 1 if ++$AUTHErrors{$ip} <= $MaxAUTHErrors;
    $this->{messagereason}="too many AUTH errors from $ip";
    pbAdd( $fh, $this->{ip}, 'autValencePB', 'AUTHErrors' ) if ! matchIP($ip,'noPB',0,1);
    $AUTHErrors{$ip}++;
    return 0;
}
