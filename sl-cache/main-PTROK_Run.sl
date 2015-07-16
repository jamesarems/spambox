#line 1 "sub main::PTROK_Run"
package main; sub PTROK_Run {
    my $fh = shift;
    my $this=$Con{$fh};
    d('PTROK');
    return 1 if $this->{PTROK};
    $this->{PTROK} = 1;
    my $ip = $this->{ip};
    $ip = $this->{cip} if $this->{ispip} && $this->{cip};
    my $tlit;
    my %PTRs = ();
    skipCheck($this,'spfok','aa','ro','co','ispcip') && return 1;

    #return 1 if $this->{contentonly};
    return 1 if $this->{whitelisted}  && !$DoReversedWL && !$DoReversedWLw;
    return 1 if ($this->{noprocessing} & 1) && !$DoReversedNP && !$DoReversedNPw;
    return 1 if (($this->{rwlok} && ! $this->{cip}) or ($this->{cip} && pbWhiteFind($ip)));

    my %cache;
    ($cache{ct},$cache{status},$cache{ptrdsn}) = PTRCacheFind($ip);
    return 1 if ($cache{status} == 2);
    my $slok=$this->{allLovePTRSpam}==1;
    my $DoReversed = $DoReversed;
    my $DoInvalidPTR = $DoInvalidPTR;
    $DoReversed = 3 if ($DoReversed == 0 || $DoReversed == 2) && ($DoInvalidPTR == 1 || $DoInvalidPTR == 3);
    $DoReversed = $DoInvalidPTR = 3 if ($switchSpamLoverToScoring && $DoPenaltyMessage && ($slok || $this->{spamlover} & 1))
                                     or
                                       ($switchTestToScoring && $DoPenaltyMessage && ($ptrTestMode || $allTestMode));

    $tlit=&tlit($DoReversed);
    $this->{prepend}="[PTRmissing]";
    $this->{ptrdsn} = '';

    if ($cache{status} == 1) {
        $this->{messagereason}="PTR missing";
        mlog($fh,"$tlit ($this->{messagereason}) - Cache") if $ValidateSenderLog;
        return 1 if $DoReversed==2;
        pbAdd($fh,$ip,'ptmValencePB','PTRmissing');
        return 1 if $DoReversed==3;
        unless ($slok) {$Stats{ptrMissing}++};
        return 0;
    }
    if ($DoInvalidPTR && $cache{status} == 3) {
        $this->{ptrdsn} = $cache{ptrdsn};
        %PTRs = &BombWeight($fh,$this->{ptrdsn},'invalidPTRRe' ) if $this->{ptrdsn} && $invalidPTRRe;
        if ($this->{ptrdsn} && $DoInvalidPTR && $PTRs{count} && $this->{ptrdsn} !~ /$validPTRReRE/) 			{
            $this->{messagereason}="PTR invalid '$PTRs{matchlength}$this->{ptrdsn}'";
            $this->{prepend}="[PTRinvalid]";
            my $tlit = ($DoInvalidPTR == 1 && $PTRs{sum} < ${'ptiValencePB'}[0]) ? &tlit(3) : $tlit;
            mlog($fh,"$tlit ($this->{messagereason}) - Cache") if $ValidateSenderLog;
            return 1 if $DoInvalidPTR==2;
            pbAdd($fh,$ip,calcValence($PTRs{sum},'ptiValencePB'),"PTRinvalid") if $PTRs{sum} > 0;
            return 1 if $DoInvalidPTR==3 || $PTRs{sum} < ${'ptiValencePB'}[0];
            unless ($slok) {$Stats{ptrInvalid}++};
            return 0;
        }
    }
    %PTRs = ();
    $this->{ptrdsn} = $cache{ptrdsn};
    $this->{prepend}='';
    my $res = $this->{ptrdsn} ? '' : getDNSResolver();

    my $ip_address = $ip;
    if ($ip_address) {
        my $query;
        if (ref($res) && ! $this->{ptrdsn}) {
            &sigoff(__LINE__);
            $query = eval {$res->search($ip_address,'PTR');};
            if ($@) {&sigon(__LINE__);return 1;}
            &sigon(__LINE__);
        }
        if (ref($query) || $this->{ptrdsn}) {
            my @query = $this->{ptrdsn} ? ($this->{ptrdsn}) : eval{$query->answer};
            foreach my $rr (@query) {
                if (ref $rr) {
                    next unless eval{$rr->type eq "PTR"};
                    next unless eval{$this->{ptrdsn}=$rr->ptrdname};
                }
                return 1 if ($heloBlacklistIgnore && $this->{ptrdsn} =~ /$HBIRE/);
                $this->{prepend}="[PTRinvalid]";
                %PTRs = ();
                %PTRs = &BombWeight($fh,$this->{ptrdsn},'invalidPTRRe' ) if $invalidPTRRe;
                if ($DoInvalidPTR && $PTRs{count} && $this->{ptrdsn} !~ /$validPTRReRE/) {
                    $this->{messagereason}="PTR invalid '$PTRs{matchlength}$this->{ptrdsn}'";
                    my $tlit = ($DoInvalidPTR == 1 && $PTRs{sum} < ${'ptiValencePB'}[0]) ? &tlit(3) : $tlit;
                    mlog($fh,"$tlit ($this->{messagereason})") if $ValidateSenderLog;
                    PTRCacheAdd($ip,3,$this->{ptrdsn});
                    return 1 if $DoInvalidPTR==2;
                    pbAdd($fh,$ip,calcValence($PTRs{sum},'ptiValencePB'),"PTRinvalid") if $PTRs{sum} > 0;
                    return 1 if $DoInvalidPTR==3 || $PTRs{sum} < ${'ptiValencePB'}[0];
                    unless ($slok) {$Stats{ptrInvalid}++};
                    return 0;
                }
                PTRCacheAdd($ip,2,$this->{ptrdsn});
                mlog($fh,"$tlit found valid PTR $this->{ptrdsn}") if $ValidateSenderLog >= 2;
                return 1;
            }
        } else {
            if (eval{ref($res) && $res->errorstring =~ /NXDOMAIN|NOERROR/o}) {
                $this->{prepend}="[PTRmissing]";

                $this->{messagereason}="PTR missing";
                PTRCacheAdd($ip,1);
                mlog($fh,"$tlit ($this->{messagereason})") if $ValidateSenderLog;
                return 1 if $DoReversed==2;
                pbAdd($fh,$ip,'ptmValencePB','PTRmissing') ;
                return 1 if $DoReversed==3;
                unless ($slok) {$Stats{ptrMissing}++};
                return 0;
            }
        }
    }
    mlog($fh,"$tlit PTR unchecked - " . eval{$res->errorstring}) if $ValidateSenderLog >= 2;
    return 1;
}
