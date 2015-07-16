#line 1 "sub main::batv_mail_out"
package main; sub batv_mail_out {
    my ($fh,$mailfrom) = @_;
    my $this = $Con{$fh};
    my $domain;
    my $user;
    my $numsec;
    my $gennum = int rand(20);
    my $orgsender = $mailfrom;

    return $mailfrom unless $this->{relayok};
    return $mailfrom unless $DoBATV;
    return $mailfrom unless $CanUseSHA1;
    return $mailfrom if (&matchSL($mailfrom,'noBackSctrAddresses'));

    if ($mailfrom =~ /([^@]*)@([^@]*)/o) {
        $user = $1;
        $domain = $2;
    }
    return $mailfrom unless $domain;
    return $mailfrom unless $user;

    $numsec = @batv_secrets;
    unless ($numsec) {
        mlog(0, "warning : config error - no BATV-secrets (BATVSec) defined");
        return $mailfrom;
    }
    $gennum = rand($numsec);
    my $gen = $batv_secrets[$gennum]{gen};
    my $secret = $batv_secrets[$gennum]{secret};
    my $day = sprintf("%03d", (time / 86400 + 7) % 1000);
    my $hash_source =  $gen . $day . $mailfrom;
    my $tagval = $gen . $day . substr(sha1_hex($hash_source . $secret), 0, 6);
    $user = "prvs=$tagval=" . $user;
    $mailfrom = $user . '@' . $domain;
    mlog($fh, "info: calculated BATVhash from: generation: $gen, key: $secret, day: $day address: $orgsender") if $BATVLog >= 2;
    mlog($fh, "info : changed sender from $orgsender to $mailfrom") if $BATVLog;
    return $mailfrom;
}
