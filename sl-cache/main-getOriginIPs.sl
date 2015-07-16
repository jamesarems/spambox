#line 1 "sub main::getOriginIPs"
package main; sub getOriginIPs {
    my ($head, $ip, $cip, $getPTR, $fh) = @_;
    my $header = ref $head ? $$head : $head;
    my %ips;
    my $oip;
    my @sips;
    my %ptr;
    my @ignoredIP;
    d('getOriginIPs');
    $getPTR = (lc $getPTR eq 'ptr') ? 1 : 0;
    while ( $header =~ /(?:Received:\s+from\s+|(?:Origin(?:at(?:ing|ed))?|Source|client)[\s\-_]?IP:|[\s\-_]IP:)($HeaderValueRe)/gois ) {
        my $line = $1;
        headerSmartUnwrap($line);
        my @words = $line =~ /\b(from|helo|by|for|with)\b/goi;
        while (@words) {
            while (@words && lc $words[0] ne 'with') {shift @words;}
            if (@words) {
                shift @words;
                if ($words[0]) {
                    if (lc $words[0] eq 'for') {
                        $line =~ s/\bwith\b.*$//o unless ( $line =~ s/\bwith\b.*?\b$words[0]\b(?:\s*"[^"]+")?\s*<?$EmailAdrRe\@$EmailDomainRe//i);
                    } else {
                        $line =~ s/\bwith\b.*?(\b$words[0]\b)/$1/i;
                    }
                } else {
                    $line =~ s/\bwith\b.*$//o;
                }
            }
        }
        $line =~ s/ by ($IPRe) / by [$1] /igo;
        $line =~ s/(?:ecelerity|id|SMTPSVC|version).+?$IPRe//iog;
        while ($line =~ /[\[\(]($IPRe)[\]\)]/go) {
            my $sip = $1;
            next if ($sip =~ /\.0+$/o && $sip !~ /^$IPv6Re/o);
            next unless $sip;
            if ($sip =~ /^$IPprivate/o) {
                next if exists $ips{$sip};
                push @ignoredIP,$sip;
                $ips{$sip} = 1;
                next;
            }
            my @sip = ( ipv6expand(ipv6TOipv4($sip)) , ipv6expand($sip) );
            pop @sip if ($sip[0] eq $sip[1]);
            for my $sip (@sip) {
                next if exists $ips{$sip};
                push @ignoredIP,$sip;
                next if $sip eq $cip;
                next if $sip eq $ip;
                next if $sip =~ /^$IPprivate/o;
                next if matchIP($sip,'ispip',0,0);
                next if matchIP($sip,'acceptAllMail',0,0);
                next if matchIP($sip,'whiteListedIPs',$fh,0);
                next if matchIP($sip,'noProcessingIPs',$fh,0);
                next if matchIP($sip,'noDelay',$fh,0);
                next if matchIP($sip,'noPB',0,0);

                pop @ignoredIP;
                push @sips, $sip;
                $oip = $sip;
                $ips{$sip} = 1;
                $ptr{$sip} = getRRData($sip,'PTR') if $getPTR;
            }
        }
    }
    mlog(0,"info: enhanced Originated IP detection ignored IP's: ".join(' ,',@ignoredIP)) if $ConnectionLog >= 2 && @ignoredIP;
    mlog(0,"info: enhanced Originated IP detection found IP's: ".join(' ,',@sips)) if $ConnectionLog >= 2 && @sips;
    @sips = reverse @sips;
    return \@sips,\%ptr,$oip;
}
