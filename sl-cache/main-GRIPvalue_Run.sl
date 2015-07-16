#line 1 "sub main::GRIPvalue_Run"
package main; sub GRIPvalue_Run {
    my ( $fh, $ip ) = @_;
    d('GRIPvalue');
    my $this = $Con{$fh};
    return 1 if $this->{gripdone};
    $this->{gripdone} = 1;
    $ip = $this->{cip} if $this->{ispip} && $this->{cip};

    skipCheck($this,'sb','ro','co','nb','nbw','wl','np',sub{$ip =~ /$IPprivate/o;}
    ) && return 1;

    $this->{messagereason} = '';
    my	$ipnet = &ipNetwork($ip, 1);
    $ipnet =~ s/\.0+$//o;
    my $v;
    if ($this->{ispip} && ! $this->{cip}) {
        $v = defined $ispgripvalue ? $ispgripvalue : $Griplist{x};
        $v = undef if(! $v && $v != 0);
        $this->{messagereason} = "ISPIP $ip - use griplist value ($v)" if defined $v;
    } else {
        $v = $Griplist{$ipnet};
    }
    return 1 unless defined $v;
    return 1 if $v <= 0.7 and $v >= 0.3;
    $this->{messagereason} = $ipnet.".0 in griplist ($v)" unless $this->{messagereason};
    if ($v > 0.7) {
        pbAdd( $fh, $ip, ([int((($v - 0.7) / 0.3) * ${'gripValencePB'}[0]),int((($v - 0.7) / 0.3) * ${'gripValencePB'}[1])]), 'griplist', 1 ) ;
        return 0;
    } elsif ($v < 0.3) {
        pbAdd( $fh, $ip, ([-int(((0.3 - $v ) / 0.3) * ${'gripValencePB'}[0]),-int(((0.3 - $v ) / 0.3) * ${'gripValencePB'}[1])]), 'griplist', 1 ) ;
        return 1;
    }
    return 1;
}
