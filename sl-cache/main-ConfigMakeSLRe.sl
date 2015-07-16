#line 1 "sub main::ConfigMakeSLRe"
package main; sub ConfigMakeSLRe {
    my ( $name, $old, $new, $init, $desc ) = @_;
    my $ld;
    my $mta;
    %FlatVRFYMTA = () if $name eq "LocalAddresses_Flat";
    mlog( 0, "adminupdate: $name changed from '$old' to '$new'" )
      unless $init || $new eq $old;
    ${$name} = $new unless $WorkerNumber;
    $new = checkOptionList( $new, $name, $init );
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    my $ret = &ConfigRegisterGroupWatch(\$new,$name,$desc);

    my $mEmailDomainRe='(?:\w(?:\\\.|[\w\-])*\\\.\w\w+|\[(?:\d|\\\.)*\\\.\d+\])';
    my $mIPSectDotRe = '(?:'.$IPSectRe.'\\\.)';
    my $mIPRe = $mIPSectDotRe.$mIPSectDotRe.$mIPSectDotRe.$IPSectRe;
    my $mHostRe = '(?:' . $mIPRe . '|' . $mEmailDomainRe . '|\w\w+)';
    my $mHostPortRe = $mHostRe . '(?:\:' . $PortRe . ')?' . '(?:,' . $mHostRe . '(?:\:' . $PortRe . ')?)*';

    $new =~ s/([\\]\|)*\|+/$1\|/go;
    $new =~ s/\./\\\./go;
    $new =~ s/\*/\.\{0,64\}/go;

    my ( @uad, @u, @d , %entry_uad, %entry_u, %entry_d, $defaultMTA, %toChangeMTA);

    foreach my $ad ( split( /\|/o, $new ) ) {
        $ad =~ s/\s//go;
        if ( $ad =~ /\S\@\S/o ) {
            push( @uad, $ad ) unless exists $entry_uad{lc $ad};
            $entry_uad{lc $ad} = 1;
        } elsif ( $ad =~ /^\@/o ) {
            if ( $name eq "LocalAddresses_Flat" ) {
                ( $ld, $mta ) = split( /\s*\=\>\s*/o, $ad );
                if ($mta && $mta =~ /$mHostPortRe/o) {
                    $FlatVRFYMTA{ lc (unescape($ld)) } = unescape($mta);
                    $ad = $ld;
                } elsif ($mta) {
                   $ret .= ConfigShowError(0,"warning: localDomains - VRFY entry '$ad' contains a not valid MTA definition")
                       if $WorkerNumber == 0;
                   next;
                }
                $ret .= ConfigShowError(0,"warning: LocalAddresses_Flat VRFY entry ".unescape($ld)." also exists in localDomains")
                   if &matchHashKey('DomainVRFYMTA', lc (unescape($ld)) ) && $WorkerNumber == 0;
            }
            $toChangeMTA{lc (unescape($ad))} = 1;
            $ad =~ s/^\@//o;
            push( @d, $ad ) unless exists $entry_d{lc $ad};
            $entry_d{lc $ad} = 1;
        } elsif ( $name eq "LocalAddresses_Flat"
            && $LocalAddresses_Flat_Domains )
        {

            ( $ld, $mta ) = split( /\s*\=\>\s*/o, $ad , 2);
            if ($ld =~ /^(all)$/io) {
               my $e = $1;
               if ($mta !~ /$mHostPortRe/o) {
                   $ret .= ConfigShowError(0,"warning: localDomains - VRFY entry '$ad' contains a not valid MTA definition")
                       if $WorkerNumber == 0;
                   next;
               }
               $ret .= ConfigShowError(0,"warning: LocalAddresses_Flat - duplicate VRFY entry '$e' found - '$ad' will be used")
                   if $defaultMTA && $WorkerNumber == 0;
               $defaultMTA = $mta;
               next;
            } elsif ($ld !~ /\./o) {
                $ret .= ConfigShowError(0,"warning: LocalAddresses_Flat - entry '".unescape($ad)."' contains no valid domain name - assume it is a user name")
                   if $WorkerNumber == 0;
                push( @u, $ld ) unless exists $entry_u{lc $ld};
                $entry_u{lc $ld} = 1;
                $toChangeMTA{lc (unescape($ld))} = 1;
                next;
            }
            $ld = '@' . $ld;
            $ad = '@' . $ad;
            if ($mta && $mta =~ /$mHostPortRe/o) {
                $FlatVRFYMTA{ lc (unescape($ld)) } = unescape($mta) if $mta;
                $ret .= ConfigShowError(0,"warning: LocalAddresses_Flat VRFY entry ".unescape($ld)." also exists in localDomains")
                   if &matchHashKey('DomainVRFYMTA', lc (unescape($ld)) ) && $WorkerNumber == 0;
            } elsif ($mta && $mta !~ /$mHostPortRe/o) {
                $ret .= ConfigShowError(1,"error: found entry '".unescape($ad)."' with wrong syntax in LocalAddresses_Flat file") if $WorkerNumber == 0;
                next;
            }

            if ($mta) {
                $ad = $ld if $mta;
            } else {
                $toChangeMTA{lc (unescape($ld))} = 1;
            }
            $ad =~ s/^\@//o;
            push( @d, $ad ) unless exists $entry_d{lc $ad};
            $entry_d{lc $ad} = 1;
        } else {
            if ( $name eq 'LocalAddresses_Flat' ) {
                ( $ld, $mta ) = split( /\s*\=\>\s*/o, $ad , 2);
                if ($mta && $mta =~ /$mHostPortRe/o) {
                    if ($ld =~ /^(all)$/io) {
                       $ret .= ConfigShowError(0,"warning: LocalAddresses_Flat - duplicate VRFY entry '$1' found - '$ad' will be used")
                           if $defaultMTA && $WorkerNumber == 0;
                       $defaultMTA = $mta;
                       next;
                    } elsif ($ld !~ /\./o) {
                        $ret .= ConfigShowError(0,"warning: LocalAddresses_Flat - entry '".unescape($ad)."' contains no valid domain name - assume it is a user name")
                            if $WorkerNumber == 0;
                        push( @u, $ld ) unless exists $entry_u{lc $ld};
                        $entry_u{lc $ld} = 1;
                        $toChangeMTA{lc (unescape($ld))} = 1;
                        next;
                    }
                    $ld = '@' . $ld;
                    $ad = '@' . $ad;
                    if ($mta) {
                        $FlatVRFYMTA{ lc (unescape($ld)) } = unescape($mta);
                    } else {
                        $toChangeMTA{lc (unescape($ld))} = 1;
                    }
                    $ret .= ConfigShowError(0,"warning: LocalAddresses_Flat VRFY entry ".unescape($ld)." also exists in localDomains")
                       if &matchHashKey('DomainVRFYMTA', lc (unescape($ld)) ) && $WorkerNumber == 0;
                    $ad  = $ld;
                    $ad =~ s/^\@//o;
                    push( @d, $ad ) unless exists $entry_d{lc $ad};
                    $entry_d{lc $ad} = 1;
                } elsif ($mta && $mta !~ /$mHostPortRe/o) {
                    $ret .= ConfigShowError(1,"error: found entry '".unescape($ad)."' with wrong syntax in LocalAddresses_Flat file")
                        if $WorkerNumber == 0;
                    next;
                } elsif ($ld =~ /^(all)$/io) {
                    $ret .= ConfigShowError(0,"warning: LocalAddresses_Flat - entry '".unescape($ad)."' contains no MTA definition")
                        if $WorkerNumber == 0;
                    next;
                } else {
                    push( @u, $ad ) unless exists $entry_u{lc $ad};
                    $entry_u{lc $ad} = 1;
                    $toChangeMTA{lc (unescape($ad))} = 1;
                }
            } else {
                push( @u, $ad ) unless exists $entry_u{lc $ad};
                $entry_u{lc $ad} = 1;
                $toChangeMTA{lc (unescape($ad))} = 1;
            }
        }
    }
    if ($defaultMTA) {
        while (my ($k,$v) = each %toChangeMTA) {
            $FlatVRFYMTA{$k} = $defaultMTA if ! exists $FlatVRFYMTA{$k};
        }
    }
    mlog(0,"AdminUpdate: enabled VRFY for address(es) ". join(' , ', keys %FlatVRFYMTA)) if $WorkerNumber == 0 && $name eq 'LocalAddresses_Flat' && scalar keys %FlatVRFYMTA;

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
