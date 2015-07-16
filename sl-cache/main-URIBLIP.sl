#line 1 "sub main::URIBLIP"
package main; sub URIBLIP {
    my ($fh, $thisip, $done, $URIIPs) = @_;
    my $this = $Con{$fh};
    $fh = 0 if "$fh" =~ /^\d+$/o;
    d('URIBLIP');
    return 1 if $URIBLIPRE =~ /$neverMatchRE/o;
    my $res = 1;
    my %saw;
    while (@$URIIPs) {
        my $ip = shift @$URIIPs;
        next unless $ip;
        next if $saw{$ip};
        $saw{$ip} = 1;
        mlog(0,"URIBLIP: check $ip") if $URIBLLog >= 2;
        if (matchIP($ip,'URIBLIPRe',$fh,0)) {
            $this->{prepend} = '[URIBL]';
            $this->{messagereason} = "IP check for URI's failed";
            pbWhiteDelete( $fh, $thisip ) if $fh;
            pbAdd( $fh, $thisip, 'uriblValencePB', 'URIBLfailed' ) if $fh;
            mlog($fh, "URIBLIP: resolved URI-IP $ip listed in URIBLIPRe" ) if ( $URIBLLog );
            my $err = $URIBLError;
            $err =~ s/URIBLNAME/$ip/go;
            $Stats{uriblfails}++ if $fh;
            $this->{uri_listed_by} .= "$ip<-URIBLIPs;" if ($this->{skipuriblPL} || ! $fh);
            thisIsSpam($fh,$this->{messagereason},$URIBLFailLog,$err,0,0,$done) if ($fh && ! $this->{skipuriblPL});  # do not thisisspam if called from Plugin routines
            $res = 0;
            last;
        }
    }
    return $res;
}
