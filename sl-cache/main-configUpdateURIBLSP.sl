#line 1 "sub main::configUpdateURIBLSP"
package main; sub configUpdateURIBLSP {
    my ( $name, $old, $new, $init ) = @_;
    mlog( 0, "AdminUpdate: URIBL Service Providers updated from '$old' to '$new'" )
      unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    $new = checkOptionList( $new, 'URIBLServiceProvider', $init );
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    my $domains = ( $new =~ s/\|/|/go ) + 1;
    if ( $domains < $URIBLmaxreplies ) {
        mlog( 0, "AdminUpdate: warning count of URIBLServiceProvider not >= URIBLmaxreplies - possibly ok if weights are used" )
          if $Config{ValidateURIBL};
    }
    if ($CanUseURIBL) {
        my @templist = split( /\|/o, $new );
        @uribllist = ();
        %URIBLweight = ();
        while (@templist) {
            my $c = shift @templist;

            if ( $c =~ /^(.*?)=>(.*?)=>(.*)/o ) {
                my ($sp,$res,$w) = ($1,$2,$3);
                next unless $sp;
                $res ||= '*';
                push( @uribllist, $sp ) unless grep(/\Q$sp\E/, @uribllist);
                $sp =~ s/^.*?\$DATA\$\.?//io;
                if ($res =~ /(?:^|\.)M(?:[1248]|16|32|64|128)(?:\.|$)/io) {
                    $URIBLweight{$sp} = {} unless exists $URIBLweight{$sp};
                    setSPBitMask($URIBLweight{$sp},$res, weightURI($w),"'$name' for '$sp'");
                } elsif ($res =~ /(?:^|\.)M/io) {
                    mlog(0,"error: invalid bitmask definition '$res' found in $name for $sp") if $WorkerNumber == 0;
                    next;
                } else {
                    $URIBLweight{$sp}{$res} = weightURI($w);
                }
            } elsif ( $c =~ /^(.*?)\=\>(.*)$/o ) {
                my ($sp,$w) = ($1,$2);
                next unless $sp;
                push( @uribllist, $sp ) unless grep(/\Q$sp\E/, @uribllist);
                $sp =~ s/^.*?\$DATA\$\.?//io;
                $URIBLweight{$sp}{'*'} = weightURI($w);
            } else {
                $c =~ s/^.*?\$DATA\$\.?//io;
                next unless $c;
                push( @uribllist, $c ) unless grep(/\Q$c\E/, @uribllist);
                $URIBLweight{$c}{'*'} = ${'uriblValencePB'}[0];
            }
        }
        if ( $WorkerNumber == 0 && ($MaintenanceLog > 1 || $URIBLLog > 1)) {
            foreach my $sp (sort keys %URIBLweight) {
                my $num = scalar keys %{$URIBLweight{$sp}};
                if ($num > 1) {
                    my $tag = $num < 1025 ? 'info' : $num < 2049 ? 'warning' : 'error';
                    mlog(0,"$tag: $name: registered $num reply weights for $sp");
                }
            }
        }
        if ( $WorkerNumber == 10000 ) {
            &cleanCacheURI() unless $init || $new eq $old;
        }
        if ($ValidateURIBL) {
            return ' & URIBL activated';
        } else {
            return 'URIBL deactivated';
        }
    }
}
