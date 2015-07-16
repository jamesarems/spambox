#line 1 "sub main::PBExtremeOK"
package main; sub PBExtremeOK {
    my ( $fh, $myip, $skipcip) = @_;
    my $this = $Con{$fh};
    if (! $skipcip) {
        $myip = $this->{cip} if $this->{ispip} && $this->{cip};
        return 1 if $this->{PBExtremeOK};
        $this->{PBExtremeOK} = 1;
    }
    d('PBExtremeOK');
    my $newscore;
    my $data;
    my $ip = ($myip eq $this->{ip} || $myip eq $this->{cip}) ? '' : "(OIP: $myip) ";
    my $slok = $this->{allLovePBSpam} == 1;
    my $noBLIPs = matchIP( $myip, 'noBlockingIPs',$fh,0);

    my $byWhatList = 'denySMTPConnectionsFromAlways';
    if ((!$denySMTPstrictEarly || $skipcip) && ! $noBLIPs) {

        my $ret = matchIP( $myip, 'denySMTPConnectionsFromAlways', $fh ,0);
        $ret = matchIP( $myip, 'droplist', $fh ,0) if (! $ret && ($DoDropList == 2 or $DoDropList == 3) && ($byWhatList = 'droplist')) ;
        if ($ret && $DoDenySMTPstrict == 1 && ! matchIP( $myip, 'noPB', 0, 1 ) ) {
            $this->{prepend} = "[DenyStrict]";
            mlog( $fh, $ip."blocked by $byWhatList strict: $ret" )
              if $denySMTPLog || $ConnectionLog >= 2;
            $Stats{denyConnection}++;
            $this->{messagereason} = $ip."blocked by $byWhatList strict '$ret'";
            return 0;
        }
        if ($ret && $DoDenySMTPstrict == 2 && ! matchIP( $myip, 'noPB', 0, 1 ) ) {
            $this->{prepend} = "[DenyStrict]";
            mlog( $fh, "[monitoring] ".$ip."blocked by $byWhatList strict: $ret" )
              if $denySMTPLog || $ConnectionLog >= 2;
        }
    }

    return 1 if $this->{contentonly};
    return 1 if $this->{whitelisted}  && !$ExtremeWL;
    return 1 if ($this->{noprocessing} & 1) && !$ExtremeNP;

    if (pbWhiteFind($myip)) {
        pbBlackDelete( $fh, $myip );
        $this->{messagereason} = $ip."In Penalty White Box";
        pbAdd( $fh, $myip, 'pbwValencePB', 'InWhiteBox', 1 );
        return 1;
    }

    if (! $this->{cip}) {
        skipCheck($this,'ispip','nd','nb') && return 1;
    }
    skipCheck($this,'aa','ro') && return 1;

    $byWhatList = 'denySMTPConnectionsFromAlways';
    my $ret;
    $ret = matchIP( $myip, 'denySMTPConnectionsFromAlways', $fh ,0) if ! $noBLIPs;
    $byWhatList = 'denySMTPConnectionsFrom' unless $ret;
    $ret ||= matchIP( $myip, 'denySMTPConnectionsFrom', $fh, 0 ) if ! $noBLIPs;
    $ret ||= matchIP( $myip, 'droplist', $fh, 0 ) if (! $noBLIPs && $DoDropList && ($byWhatList = 'droplist')) ;

    if ( $ret && $DoDenySMTP == 1 ) {
        $this->{prepend} = "[DenyIP]";
        $Stats{denyConnection}++;
        $this->{messagereason} = $ip." blocked by $byWhatList '$ret'";
        return 0;
    }
    if ( $ret && $DoDenySMTP == 2 ) {
        $this->{prepend} = "[DenyIP]";
        mlog( $fh, "[monitoring] ".$ip." blocked by $byWhatList '$ret'" )
          if $PenaltyExtremeLog;
    }

    my $DoPenaltyExtreme = $DoPenaltyExtreme;
    return 1 if !$DoPenaltyExtreme;
    return 1 if !$PenaltyExtreme;
    return 1 if ( !exists $PBBlack{&ipNetwork( $myip, $PenaltyUseNetblocks )} );
    return 1 if matchIP( $myip, 'noExtremePB', $fh, 0 );
    return 1 if (! $skipcip && ($this->{nopb} || ($this->{nopb} = matchIP($myip,'noPB',$fh,1 ))));
    return 1 if ($skipcip && matchIP($myip,'noPB',$fh,1 ));
    return 1 if matchSL( &batv_remove_tag(0,$this->{mailfrom},''), 'noExtremePBAddresses' );

    my $tlit = tlit($main::DoPenaltyExtreme);

    my ( $ct, $ut, $level, $totalscore, $sip, $reason, $counter ) =
      split( ' ', $PBBlack{&ipNetwork( $myip, $PenaltyUseNetblocks )} );
    if ( $totalscore >= $PenaltyLimit && $totalscore < $PenaltyExtreme ) {
        $this->{messagereason} = "Bad IP History ($myip)";
        pbAdd( $fh, $myip, 'pbValencePB', 'BadHistory', 1 );

    }
    if ( $totalscore >= $PenaltyExtreme ) {
        $this->{messagereason} = "Extreme Bad History ($myip)->($totalscore)";
        pbAdd( $fh, $myip, 'pbeValencePB', 'ExtremeHistory', 1 );
        $this->{prepend}    = "[Extreme]";
        $this->{messagereason} = "score for $myip is $totalscore, surpassing extreme level of $PenaltyExtreme";

        mlog( $fh,"$tlit (totalscore for '$myip' is $totalscore, surpassing extreme level of $PenaltyExtreme, last penalty was '$reason')")
           if $PenaltyExtremeLog >= 2 && $DoPenaltyExtreme >= 2;
        return 1 if $DoPenaltyExtreme >= 2;
        $Stats{pbextreme}++;
        return 0;
    }
    return 1;
}
