#line 1 "sub main::delayWhiteExpire"
package main; sub delayWhiteExpire {
	my $fh   = shift;
    return unless $fh;
    my $this = $Con{$fh};
    d('delayWhiteExpire');
	my $ip = $this->{ip};
	$ip = $this->{cip} if $this->{ispip} && $this->{cip};

	pbWhiteDelete( $fh, $ip );
    SBCacheChange( $ip, 3);
	return unless ( $EnableDelaying && $DelayExpireOnSpam );
	my $mf = lc $this->{mailfrom};

	# get sender domain
	$mf =~ s/[^@]*@//o;
	my $ipn = &ipNetwork( $ip, $DelayUseNetblocks );
	my $hash = "$ipn $mf";
	$hash = Digest::MD5::md5_hex($hash) if $CanUseMD5Keys && $DelayMD5;
    my $DelayWhite_hash = $DelayWhite{$hash};
    if ( $DelayWhite_hash ) {
		# delete whitelisted (IP+sender domain) tuplet
		mlog(	$fh, "deleting spamming safelisted tuplet: ($ipn,$mf) age: "
				. formatTimeInterval( time - $DelayWhite_hash ), 1 ) if $DelayLog;
		delete $DelayWhite{$hash};
    }
}
