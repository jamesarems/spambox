#line 1 "sub main::IPinHeloOK_Run"
package main; sub IPinHeloOK_Run {
    my $fh = shift;
    my $this = $Con{$fh};
    $fh = 0 if "$fh" =~ /^\d+$/o;
    my $ip = $this->{ip};
    my $helo = $this->{helo};

    $ip = $this->{cip} if $this->{ispip} && $this->{cip};
    $helo = $this->{ciphelo} if $this->{ciphelo};
    d('IPinHeloOK');

    return 1 if $this->{IPinHeloOK} eq "$ip $helo";
    $this->{IPinHeloOK} = "$ip $helo";
    return 1 if $helo eq $ip;
    $ip = ipv6expand($ip);
    return 1 if $helo eq $ip;
    my ($to) = $this->{rcpt} =~ /(\S+)/o;
    skipCheck($this,'ro','co','aa','ispcip') && return 1;
    return 1 if $DoFakedWL && ($this->{whitelisted} || &Whitelist($this->{mailfrom},$to));
    return 1 if ( matchIP( $ip, 'noHelo', $fh ,0) );

    return 1 if $ip =~ /$IPprivate/o;
    return 1 if $heloBlacklistIgnore && $helo =~ /$HBIRE/;
    return 1 if $DoFakedNP && matchSL( $this->{mailfrom}, 'noProcessing' );

    my $tlit = tlit($DoIPinHelo);
    my @variants;

    if ( $helo =~ /\[?(?:(?:$IPSectRe(?:\.|\-)){3}$IPSectRe|(?:$IPSectHexRe(?:\.|\-)){3}$IPSectHexRe|$IPv6LikeRe)\]?/o ) {
        pos($helo) = 0;
        while ($helo =~ /\[?((?:$IPSectRe(?:\.|\-)){3}$IPSectRe(?:(?:\.|\-)$IPSectRe)*|(?:$IPSectHexRe(?:\.|\-)){3}$IPSectHexRe(?:(?:\.|\-)$IPSectHexRe)*|($IPv6LikeRe))\]?/og) {
            my $literal = $1;
            my $isV6 = $2;
            my $sep;
            # replace any '-' characters with a dot or :
            if ($isV6) {
                next if $literal =~ /\-/o && $literal =~ /\:/o;
                $literal =~ s/\-/\:/go;
                $literal = ipv6expand($literal);
                $sep = ':';
            } else {
                next if $literal =~ /\-/o && $literal =~ /\./o;
                $literal =~ s/\-/\./go;
                $literal =~ s/0x([a-fA-F0-9]{1,2})/hex($1)/goe;
                $literal =~ s/([A-F][A-F0-9]?|[A-F0-9]?[A-F])/hex($1)/gioe;
                $sep = '.';
            }

            # remove leading zeros and put it into an array
            my @octets = map {
                if ( !m/^0$/io ) {my $t = $_; $t =~ s/^0*//o; $t }
                else             { 0 }    # properly handle a 0 in the IP
            } split( /\.|\:/o, $literal );

            #put the ip back together
            if ($sep eq ':') { # IPv6
                push @variants, (join $sep, @octets);
                push @variants, (join $sep, reverse(@octets));
            } else { # IPv4
                my @o = @octets;
                my @p = reverse(@octets);
                while (scalar(@o) > 3) {
                    push @variants , "$o[0].$o[1].$o[2].$o[3]";
                    push @variants , "$o[3].$o[0].$o[1].$o[2]";
                    push @variants , "$o[2].$o[3].$o[0].$o[1]";
                    push @variants , "$o[1].$o[2].$o[3].$o[0]";

                    push @variants , "$p[0].$p[1].$p[2].$p[3]";
                    push @variants , "$p[3].$p[0].$p[1].$p[2]";
                    push @variants , "$p[2].$p[3].$p[0].$p[1]";
                    push @variants , "$p[1].$p[2].$p[3].$p[0]";

                    shift @o;
                    shift @p;
                }
            }
        }

        return 1 unless scalar @variants;
        d("saw IP in HELO: @variants");
        my $mr = $this->{messagereason} = "Suspicious HELO - contains IP: '$helo'";
        $this->{prepend} = "[SuspiciousHelo]";

        pbAdd( $fh, $ip, 'fiphValencePB', 'IPinHELO' ) if $DoIPinHelo != 2;
        mlog( $fh, "$tlit ($this->{messagereason})", 1 ) if $ValidateSenderLog;
        if ( ! grep(/^\Q$ip\E$/i,@variants) ) {
            $this->{messagereason} = "IP in HELO '$helo' does not match IP in connection '$ip' ";
            $mr .= " - and IP in HELO '$helo' does not match IP in connection '$ip' ";
            pbAdd( $fh, $ip, 'fiphmValencePB', 'IPinHELOmismatch' ) if $DoIPinHelo != 2;
            mlog( $fh, "$tlit ($this->{messagereason})", 1 ) if $ValidateSenderLog;
        }
        $this->{messagereason} = $mr unless $fh;
        $this->{prepend} = '';
        return 0;
    }

    #the if didn't hit
    return 1;
}
