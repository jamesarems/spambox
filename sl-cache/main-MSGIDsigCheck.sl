#line 1 "sub main::MSGIDsigCheck"
package main; sub MSGIDsigCheck {
    my $fh = shift;
    my $this = $Con{$fh};
    d('MSGIDsigCheck');
    my $headlen = $MaxBytes && $MaxBytes < $this->{maillength} ? $MaxBytes + $this->{headerlength} : $this->{maillength};
    my $tocheck = substr($this->{header},0,$headlen);
    while (my ($cline,$line, $gen, $day, $hash, $orig_msgid) = ($tocheck =~ /(($HeaderNameRe\:)[\r\n\s]*?\<$MSGIDpreTag\.(\d)(\d\d\d)(\w{6})\.([^\r\n>]+)\>)/)) {
        my $pos = index($tocheck, $cline) + length($cline);
        $tocheck = substr($tocheck,$pos,length($tocheck) - $pos);
        my $secret;
        for (@msgid_secrets) {
            if ($_->{gen} == $gen) {
                $secret = $_->{secret};
                last;
            }
        }
        next unless ($secret);
        my $hash_source =  $gen . $day . $orig_msgid;
        my $hash2 = substr(sha1_hex($hash_source . $secret), 0, 6);
        if ($hash eq $hash2) {
            my $today = (time / 86400) % 1000;
            my $dt = ($day - $today + 1000) % 1000;
            if ($dt <= 7) {
                $this->{nopb} = 1;
                mlog($fh, "info: found valid MSGID signature in [$line] - accept mail") if $MSGIDsigLog or $this->{noMSGIDsigLog};
                return 1;
            } else {
                mlog($fh, "info: found expired MSGID signature in [$line]") if $MSGIDsigLog or $this->{noMSGIDsigLog};
            }
        }
    }
    # bounce without MSGID sig - bad
    mlog($fh, "info: found bounced sender: \<$this->{mailfrom}\> and recipient: \<$this->{rcpt}\> without valid MSGID-signature") if ($MSGIDsigLog && ! $this->{noMSGIDsigLog});
    return 0;
}
