#line 1 "sub main::batv_rcpt_in"
package main; sub batv_rcpt_in {
    my ($fh,$rcpt) = @_;
    my $this = $Con{$fh};
    my $user;
    my $domain;

    if ($rcpt =~ /([^@]*)@([^@]*)/o) {
        $user = $1;
        $domain = $2;
    }
    return $rcpt,-1 if $this->{relayok};
    return $rcpt,-1 unless $this->{isbounce};
    return $rcpt,-1 unless $DoBATV;
    return $rcpt,-1 unless $domain;
    return $rcpt,-1 unless $user;
    return $rcpt,-1 unless $CanUseSHA1;
    return $rcpt,-1 if ($this->{whitelisted} && !$BackWL);
    return $rcpt,-1 if (($this->{noprocessing} & 1) && !$BackNP);
    return $rcpt,-1 if &matchIP($this->{ip},'noBackSctrIP',$fh,0);
    return $rcpt,-1 if (&matchSL([$rcpt,$this->{mailfrom}],'noBackSctrAddresses'));
    if ($noBackSctrRe && $this->{header} =~ /(noBackSctrReRE)/) {
       mlogRe($fh,($1||$2),'noBackSctrRe','nobackscatter');
       return $rcpt,-1;
    }
    return $rcpt,-1 if ($noBackSctrRe && $this->{header} =~ /noBackSctrReRE/);

    if (my ($gen, $day, $hash, $orig_user) = ($user =~ /^prvs=(\d)(\d\d\d)(\w{6})=([^\r\n]*)/o)) {
        my $secret;
        for (@batv_secrets) {
            if ($_->{gen} == $gen) {
                $secret = $_->{secret};
                last;
            }
        }
        unless ($secret) {
            mlog($fh, "waring: no BATV secret key found in config for generation $gen in $user - key was maybe deleted from configuration") if $BATVLog;
            return $rcpt,-1;
        }
        my $orig_address =  $orig_user . '@' . $domain ;
        my $hash_source =  $gen . $day . $orig_address;
        my $hash2 = substr(sha1_hex($hash_source . $secret), 0, 6);
        mlog($fh, "info: calculated BATV hash-is: $hash2, generation: $gen, key: $secret, day: $day address: $orig_address") if $BATVLog >= 2;
        if ($hash eq $hash2) {
            my $today = (time / 86400) % 1000;
            my $dt = ($day - $today + 1000) % 1000;
            if ($dt <= 7) {
                mlog($fh, "info: BATV accepted mail for address $orig_address") if $BATVLog;
                return $orig_address,1;
            } else {
                mlog($fh, "info: found expired BATV address $rcpt") if $BATVLog;
                return $rcpt,0;
            }
        } else {
            mlog($fh, "info: found garbled BATV address $rcpt") if $BATVLog;
            mlog($fh, "info: hash-has: $hash, hash-is: $hash2, generation: $gen, key: $secret, day: $day") if $BATVLog >= 2;
            return $rcpt,0;
        }
    } else {
        # bounce without BATV address - bad
        mlog($fh, "info: found bounced sender: \<$this->{mailfrom}\> and recipient: \<$rcpt\> without BATVTag") if ($BATVLog && $DoBATV != 4);
        return $rcpt,0;
    }
}
