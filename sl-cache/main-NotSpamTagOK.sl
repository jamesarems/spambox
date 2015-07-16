#line 1 "sub main::NotSpamTagOK"
package main; sub NotSpamTagOK {       # tag must be exact 10 bytes long, contains a-zA-Z02-7
    my ($fh,$tag) = @_;
    return unless $fh;
    return unless $tag;
    return unless $NotSpamTag;
    $tag =~ s/0/o/og;
    $tag = unpack("H*",base32decode(lc $tag));
    return unless $tag;
    my $this = $Con{$fh};
    return if $this->{relayok} && ! $noRelayNotSpamTag;
    $fh = 0 if $fh =~ /^\d+$/o;
    my $salt = unpack("B*", $NotSpamTag);  # in bits
    my $len = min(length($salt),1031);               # get random 32 bits
    $salt .= '0' x (32 - $len) if $len < 32;
    $len = min(length($salt),1031);
    my ($start,$day,$sec) = lc($tag) =~ /(\d{3})(\d{3})([a-f0-9]{6})/o or return;
    my $today = (time / 86400) % 1000;
    my $dt = ($day - $today + 1000) % 1000;
    my $salt = unpack("B32",substr($salt,$start,32));
    my $mf = batv_remove_tag(0,lc $this->{mailfrom},'');
    my ($to) = lc($this->{rcpt}) =~ /(\S+)/o;
    if (lc(substr(sha1_hex($salt." $mf $to"),0,6)) eq lc($sec)) {
        if ($fh && exists $seenNotSpamTag{"$mf $to $start $day ".lc($sec)}) {
            mlog($fh,"info: NotSpamTag was already used at: ". timestring($seenNotSpamTag{"$mf $to $start $day ".lc($sec)})) if $SessionLog;
            $this->{myheader}.= "X-Assp-NotSpamTag: already used\r\n";
            return;
        }
        if ($dt > 2) {  # tag is too old
            mlog($fh,"info: NotSpamTag is older than two days") if $SessionLog;
            $this->{myheader}.= "X-Assp-NotSpamTag: too old\r\n";
            return;
        }
        my $f;
        $this->{myheader} =~ s/X-Assp-NotSpamTag.+$//os;
        if ($NotSpamTagProc & 1) {
            $this->{whitelisted} = 1;
            $this->{myheader}.= "X-Assp-NotSpamTag: valid - whitelisted\r\n";
            mlog($fh,"info: valid NotSpamTag found - NotSpamTagProc whitelisted") if $SessionLog;
            $f = 1;
        }
        if ($NotSpamTagProc & 2) {
            $this->{noprocessing} = 1;
            $this->{myheader}.= "X-Assp-NotSpamTag: valid - noprocessing\r\n";
            mlog($fh,"info: valid NotSpamTag found - NotSpamTagProc noprocessing") if $SessionLog;
            $f = 1;
        }
        $this->{nopb} = 1;
        pbBlackDelete($fh, $this->{ip});
        mlog($fh,"info: valid NotSpamTag found - no action in NotSpamTagProc configured") if $SessionLog && ! $f;
        $this->{myheader}.= "X-Assp-NotSpamTag: valid - no action\r\n" unless $f;
        $seenNotSpamTag{"$mf $to $start $day ".lc($sec)} = time if $fh;
        return 1;
    }
    return;
}
