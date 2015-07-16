#line 1 "sub main::MSGIDaddSig_Run"
package main; sub MSGIDaddSig_Run {
    my ($fh,$msgid) = @_;
    d('MSGIDaddSig');
    my $this = $Con{$fh};
    my $str;
    my $numsec;
    my $gennum = int rand(20);

    return $msgid if($this->{addMSGIDsigDone});
    $this->{addMSGIDsigDone} = 1;
    return $msgid unless $this->{relayok};
    return $msgid if ($noRedMSGIDsig && $this->{red});
    return $msgid if ($MSGIDsigAddresses && ! matchSL($this->{mailfrom},'MSGIDsigAddresses'));
    return $msgid if ( matchSL([$this->{rcpt},$this->{mailfrom}],'noBackSctrAddresses'));
    return $msgid if ($noMSGIDsigRe && substr($this->{header},0,$MaxBytes + $this->{headerlength}) =~ /$noMSGIDsigReRE/i);

    if ($msgid =~ /[^<]+\<([^<>]+)\>/o) {
        $str = $1;
    }
    return $msgid unless $str;

    $numsec = @msgid_secrets;
    unless ($numsec) {
        mlog(0, "warning : config error - no MSGID-secrets (MSGIDSec) defined");
        return $msgid;
    }
    $gennum = rand($numsec);
    my $gen = $msgid_secrets[$gennum]{gen};
    my $secret = $msgid_secrets[$gennum]{secret};
    my $day = sprintf("%03d", (time / 86400 + 7) % 1000);
    my $hash_source =  $gen . $day . $str;
    my $tag = $MSGIDpreTag . '.' . $gen . $day . substr(sha1_hex($hash_source . $secret), 0, 6). '.';
    my $tagval = $tag.$str;
    $msgid =~ s/\Q$str\E/$tagval/;
    mlog($fh, "info: added MSGID signature '$tag' to header") if $MSGIDsigLog >= 2;
    $this->{nodkim} = 1;
    return $msgid;
}
