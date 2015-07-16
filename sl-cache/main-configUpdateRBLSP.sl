#line 1 "sub main::configUpdateRBLSP"
package main; sub configUpdateRBLSP {
    my ( $name, $old, $new, $init ) = @_;
    mlog( 0, "AdminUpdate: RBLServiceProvider updated from '$old' to '$new'" )
      unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    $new = checkOptionList( $new, 'RBLServiceProvider', $init );
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    my $domains = ( $new =~ s/\|/|/go ) + 1;
    $RBLmaxreplies = $domains if $RBLmaxreplies > $domains;
    if ( $domains < $RBLmaxreplies ) {
        mlog( 0, "AdminUpdate:error DNSBL disabled, RBLServiceProvider is not >= RBLmaxreplies")
            if $Config{ValidateRBL};
        $ValidateRBL = $Config{ValidateRBL} = 0;
        return
'<span class="negative">*** RBLServiceProvider must be >= RBLmaxreplies before enabling DNSBL.</span>';
    }
    elsif ($CanUseRBL) {
        my @templist = split( /\|/o, $new );

        @rbllist   = ();
        %rblweight = ();
        while (@templist) {
            my $c = shift @templist;
            if ($NODHO && $c =~ /dnsbl\.httpbl\.org/io) {
                mlog(0,"RBLSP:warning - dnsbl.httpbl.org is not supported as RBL-Service-Provider by ASSP and will be ignored - remove the entry")
                    if $WorkerNumber == 0;
                next;
            }
            if ( $c =~ /^(.*?)=>(.*?)=>(.*)$/o ) {
                my ($sp,$res,$w) = ($1,$2,$3);
                next unless $sp;
                $res ||= '*';
                push( @rbllist, $sp ) unless grep(/\Q$sp\E/, @rbllist);
                $sp =~ s/^.*?\$DATA\$\.?//io;
                if ($res =~ /(?:^|\.)M(?:[1248]|16|32|64|128)(?:\.|$)/io) {
                    $rblweight{$sp} = {} unless exists $rblweight{$sp};
                    setSPBitMask($rblweight{$sp},$res, weightRBL($w),"'$name' for '$sp'");
                } elsif ($res =~ /(?:^|\.)M/io) {
                    mlog(0,"error: invalid bitmask definition '$res' found in $name for $sp") if $WorkerNumber == 0;
                    next;
                } else {
                    $rblweight{$sp}{$res} = weightRBL($w);
                }
            } elsif ( $c =~ /^(.*?)\=\>(.*)$/o ) {
                my ($sp,$w) = ($1,$2);
                next unless $sp;
                push( @rbllist, $sp ) unless grep(/\Q$sp\E/, @rbllist);
                $sp =~ s/^.*?\$DATA\$\.?//io;
                $rblweight{$sp}{'*'} = weightRBL($w);
            } else {
                $c =~ s/^.*?\$DATA\$\.?//io;
                next unless $c;
                push( @rbllist, $c ) unless grep(/\Q$c\E/, @rbllist);
                $rblweight{$c}{'*'} = ${'rblValencePB'}[0];
            }
        }
        if ( $WorkerNumber == 0 && ($MaintenanceLog > 1 || $RBLLog > 1)) {
            foreach my $sp (sort keys %rblweight) {
                my $num = scalar keys %{$rblweight{$sp}};
                if ($num > 1) {
                    my $tag = $num < 1025 ? 'info' : $num < 2049 ? 'warning' : 'error';
                    mlog(0,"$tag: $name: registered $num reply weights for $sp");
                }
            }
        }
        if ( $WorkerNumber == 10000 ) {
            &cleanCacheRBL() unless $init || $new eq $old;
        }

        if ($ValidateRBL) {
            return ' & DNSBL activated';
        }
        else {
            return 'DNSBL deactivated';
        }
    }
}
