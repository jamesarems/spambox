#line 1 "sub main::pbTrapAdd"
package main; sub pbTrapAdd {
    my ($fh,$address)=@_;
    $address = lc $address;
    return if (!$DoPenaltyMakeTraps || $DoPenaltyMakeTraps == 3);
    return unless $PenaltyMakeTraps;
    my $this=$Con{$fh};
    return if matchIP($this->{ip},'noProcessingIPs',$fh,0);
    return if matchSL($address,'noPenaltyMakeTraps');
    return if matchSL($address,'spamtrapaddresses');
    return if matchIP($this->{ip},'noPB',0,1);
    return if $LDAPoffline or $this->{userTempFail};
    my $t=time;
    lock($PBTrapLock) if $lockDatabases;

    if (my($ct,$ut,$counter)=split(/\s+/o,$PBTrap{$address})) {
        $counter++;
        $PBTrap{$address}="$ct $t $counter";
    } else {
        $PBTrap{$address}="$t $t 1";
    }
}
