#line 1 "sub main::pbTrapFind"
package main; sub pbTrapFind {
    my ($fh, $address) = @_;
    return 0 unless $address;
    return 0 unless ($PBTrapObject);
    return 0 if (!$DoPenaltyMakeTraps );
    $address = lc $address;
    if (matchSL($address,'noPenaltyMakeTraps')) {
        pbTrapDelete($address);
        return 0;
    }
    my $counter = [split(/\s+/o,$PBTrap{$address})]->[2];
    return 0 if $counter < $PenaltyMakeTraps;
    my $this;
    $this = $Con{$fh} if ($fh);
    if (! ($this && @{$this->{trapaddr}} && &matchARRAY(qr/^\Q$address\E$/ ,\@{$this->{trapaddr}})) ) {
        mlog(0,"PB: trap address $address found, counter=$counter",1)
            if (($DoPenaltyMakeTraps != 2 && $PenaltyLog) || ($DoPenaltyMakeTraps == 2 && $PenaltyLog > 1));
        push(@{$this->{trapaddr}}, $address) if $this;
        pbTrapAdd($fh,$address) if $fh;
    }
    return $DoPenaltyMakeTraps != 2;
}
