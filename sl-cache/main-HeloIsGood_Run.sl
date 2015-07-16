#line 1 "sub main::HeloIsGood_Run"
package main; sub HeloIsGood_Run {
    my($fh,$fhelo)=@_;
    return 1 unless $useHeloGoodlist;
    my $this=$Con{$fh};
    d('HeloIsGood');
    skipCheck($this,'ro','co','nohelo','ispcip') && return 1;
    return 1 if $this->{whitelisted} && !$DoHeloWL;
    return 1 if ($this->{noprocessing} & 1) && !$DoHeloNP;

    my $ip = $this->{ip};
    $ip = $this->{cip} if $this->{ispip} && $this->{cip};
    my $helo = lc($fhelo);
    $helo = lc($this->{ciphelo}) if $this->{ispip} && $this->{ciphelo};

    return 1 if !($HeloBlackObject);
    return 1 if $heloBlacklistIgnore && $helo =~ /$HBIRE/;
    my $val = $HeloBlack{$helo};
    return unless defined $val;

    if ($val < 1) {
        $val *= -10;
        my $wl;
        if ($useHeloGoodlist == 2 or $useHeloGoodlist == 3) {
            pbWhiteAdd($fh,$this->{ip},"KnownGoodHelo");
            $this->{whitelisted} = 1;
            $wl = '[whitelisted] ';
        }
        mlog($fh,$wl."info: found known good HELO '$helo' - weight is $val") if $ValidateSenderLog;
        if ($useHeloGoodlist == 1 or $useHeloGoodlist == 3) {
            pbAdd($fh,$ip,([int($val * ${'hlValencePB'}[0]),int($val * ${'hlValencePB'}[1])]),"KnownGoodHelo");
        }
    }
    return 1;
}
