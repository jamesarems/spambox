#line 1 "sub main::NotSpamTagGen"
package main; sub NotSpamTagGen {
    my $fh = shift;
    return unless $NotSpamTag;
    return unless $fh;
    return unless exists $Con{$fh};
    my $this = $Con{$fh};
    return if $this->{relayok} && ! $noRelayNotSpamTag;
    return $this->{notspamtag} if $this->{notspamtag};
    my $salt = unpack("B*", $NotSpamTag);  # in bits
    my $len = min(length($salt),1031);               # get random 32 bits
    $salt .= '0' x (32 - $len) if $len < 32;
    $len = min(length($salt),1031);
    my $start = 0;
    if ($len > 32) {
        $start = min(int(rand($len - 32)),999);
        $salt = substr($salt,$start,32);
    }
    $start = sprintf("%03d", $start);
    $salt = unpack("B32",$salt);
    my $day = sprintf("%03d", (time / 86400 + 2) % 1000);
    my $mf = batv_remove_tag(0,lc $this->{mailfrom},'');
    my ($to) = lc($this->{rcpt}) =~ /(\S+)/o;
    my $ret = base32encode(pack('H*',$start.$day.substr(sha1_hex($salt." $mf $to"),0,6)));
    $ret = join('', map {(/[a-z]/o && int(rand(2))) ? $_ : uc($_)} split('',$ret));
    $this->{notspamtag} = $ret;
    return $ret;
}
