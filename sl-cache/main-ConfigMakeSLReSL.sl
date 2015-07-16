#line 1 "sub main::ConfigMakeSLReSL"
package main; sub ConfigMakeSLReSL {
    my ( $name, $old, $new, $init, $desc ) = @_;
    my $ld;
    my $mta;
    $SLscore{$name} = {};
    mlog( 0, "adminupdate: $name changed from '$old' to '$new'" )
      unless $init || $new eq $old;
    ${$name} = $new unless $WorkerNumber;
    $new = checkOptionList( $new, $name, $init );
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    my $ret = &ConfigRegisterGroupWatch(\$new,$name,$desc);

    $new =~ s/([\\]\|)*\|+/$1\|/go;
    $new =~ s/\./\\\./go;
    $new =~ s/\*/\.\{0,64\}/go;

    my ( @uad, @u, @d , %entry_uad, %entry_u, %entry_d);

    foreach ( split( /\|/o, $new ) ) {
        my ($ad, $score) = split /=>/o;
        $ad =~ s/\s//go;
        if ($score && ! ($score =~ s/^\s*(\d+(?:\.\d+)?)\s*$/$1/o)) {
            $score = undef;
            $ret .= ConfigShowError( 0, "warning: spamlover max score for $name in definition '$_' is not a numbered value - the score value is ignored" );
        }
        my $adlc = lc $ad;
        my $adue = unescape($adlc);
        $SLscore{$name}->{$adue} = max($SLscore{$name}->{$adue},$score) if defined $score;
        if ( $ad =~ /\S\@\S/o ) {
            if (! exists $entry_uad{$adlc} ) {
                push( @uad, $ad );
                $adue =~ s/\@/\\@/io;
            }
            $entry_uad{$adlc} = 1;
        } elsif ( $ad =~ s/^\@//o ) {
            if (! exists $entry_d{$adlc} ) {
                push( @d, $ad );
                $adue =~ s/\@/\.\*\?\\@/io;
            }
            $entry_d{$adlc} = 1;
        } else {
            if (! exists $entry_u{$adlc} ) {
                push( @u, $ad );
                $adue .= '\@' if $adue !~ /\@$/o;
                $adue .= '.*';
            }
            $entry_u{$adlc} = 1;
        }
        $SLscore{$name}->{$adue} = max($SLscore{$name}->{$adue},$score) if defined $score;
    }

    my @s;
    push( @s, '(?:' . join( '|', sort @u ) . ')@.*' )   if @u;
    push( @s, '(?:' . join( '|', sort @uad ) . ')' ) if @uad;
    push( @s, '.*?@(?:' . join( '|', sort @d ) . ')' ) if @d;
    my $s;
    $s = '(?:^(?:' . join( '|', @s ) . ')$)' if @s;
    $s =~ s/\@/\\\@/go;
    $s ||= $neverMatch;    # regexp that never matches
    $ret .= ConfigShowError( 1, "ERROR: !!!!!!!!!! missing MakeSLRE{$name} in code !!!!!!!!!!" )
      if ! exists $MakeSLRE{$name} && $WorkerNumber == 0;

    SetRE( $MakeSLRE{$name}, $s,
           $regexMod,
           $desc , $name);
    return $ret . ConfigShowError(1,$RegexError{$name});
}
