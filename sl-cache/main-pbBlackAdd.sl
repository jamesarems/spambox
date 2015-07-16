#line 1 "sub main::pbBlackAdd"
package main; sub pbBlackAdd {
    my ( $fh, $myip, $score, $reason ) = @_;
    return unless $fh;
    return if !$DoPenalty;
    my $this = $Con{$fh};
    $myip = $this->{cip} if $this->{ispip} && $this->{cip} && $myip eq $this->{ip};
    my $t = time;
    my $ip = &ipNetwork( $myip, 1);
    lock($PBBlackLock) if $lockDatabases;
    if ($this->{nopb} || matchIP($myip,'noPB',0,1)) {
        $this->{nopb} = 1;
        delete $PBBlack{$myip};
        delete $PBBlack{$ip};
        return;
    }
    return if $score == 0;
    my ( $ct, $ut, $freq, $oldscore, $sip, $sreason ) = split( / /o, $PBBlack{$ip} );
    my $newscore = $oldscore + $score;
    if ( $ct ) {
        if ( $newscore <= 0 ) {
            delete $PBBlack{$myip};
            delete $PBBlack{$ip};
            return;
        }

        $freq++;
        my $text;
        $text = " to GLOBALPB entry ($oldscore)"
          if $PenaltyLog >= 2 && $sreason =~ /^GLOBALPB/o;
        $sreason = $reason if $score > 0;
        my $data = "$ct $t $freq $newscore $myip $sreason";
        $PBBlack{$myip} = $data;
        $PBBlack{$ip} = $data;
        mlog( $fh, "PB-IP-Score for '$myip' is $newscore, added $score for $reason$text", 1 )
          if $PenaltyLog >= 2 ;
    } else {
        if ($score <= 0) {
            return;
        }
        my $data = "$t $t 1 $score $myip $reason";
        $PBBlack{$myip} = $data;
        $PBBlack{$ip} = $data;
        mlog( $fh, "PB-IP-Score for '$myip' is $score, added $score for $reason", 1 )
          if $PenaltyLog >= 2;
    }
    return;
}
