#line 1 "sub main::NoSpoofingOK"
package main; sub NoSpoofingOK {
    my ( $fh, $what ) = @_;
    my $this = $Con{$fh};
    d("NoSpoofingOK - $what");
    return 1 if $this->{NoSpoofingOK}{$what};
    $this->{NoSpoofingOK}{$what} = 1;
    return 1 if ! $DoNoSpoofing;
    skipCheck($this,'sb','np','ro','aa') && return 1;
    return 1 if ! $this->{$what};
    return 1 if $this->{$what} =~ /$BSRE/;

    return 1 if ! localmail( $this->{$what} ) || $LDAPoffline;

    return 1 if $onlySpoofingCheckIP && ! matchIP( $this->{ip}, 'onlySpoofingCheckIP', 0, 1);

    return 1 if matchIP( $this->{ip}, 'noSpoofingCheckIP', 0, 1 );

    return 1 if $onlySpoofingCheckDomain && ! matchSL( $this->{$what}, 'onlySpoofingCheckDomain' , 0, 1);

    return 1 if matchSL( $this->{$what}, 'noSpoofingCheckDomain' );

    my $tlit = tlit($DoNoSpoofing);
    my $toscore = 0;
    foreach (keys %{$this->{NoSpoofingOK}}) { $toscore += $this->{NoSpoofingOK}{$_}; }
    $this->{prepend}       = '[SpoofedSender]';
    $this->{messagereason} = "No Spoofing Allowed '$this->{$what}' in '$what'";
    mlog( $fh, "$tlit ($this->{messagereason})" )
           if $ValidateSenderLog && $DoNoSpoofing >= 2;

    return 1 if $DoNoSpoofing == 2 ;
    pbAdd( $fh, $this->{ip}, 'slValencePB', 'NoSpoofing' ) if $toscore < 10;
    $this->{NoSpoofingOK}{$what} = 10;
    return 1 if $DoNoSpoofing == 3 ;
    return 0;
}
