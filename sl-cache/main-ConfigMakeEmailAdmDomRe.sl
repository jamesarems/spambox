#line 1 "sub main::ConfigMakeEmailAdmDomRe"
package main; sub ConfigMakeEmailAdmDomRe {
    my ( $name, $old, $new, $init, $desc ) = @_;
    %EmailAdminDomains = ();
    mlog( 0, "adminupdate: $name changed from '$old' to '$new'" )
      unless $init || $new eq $old;
    ${$name} = $new unless $WorkerNumber;
    $new = checkOptionList( $new, $name, $init );
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    my $ret = &ConfigRegisterGroupWatch(\$new,$name,$desc);

    $new =~ s/([\\]\|)*\|+/$1\|/go;     # clean multiple pipes
    $new =~ s/\|([^=>\|]+=>)/;$1/go;    # change entry sep  from | to ;
    $new =~ s/\|/,/go;                  # change domain sep from | to ,
    $new =~ s/;/\|/go;                  # change entry sep  from ; to |

    foreach ( split( /\|/o, $new ) ) {
        my ($ad, $domain) = split /=>/o;
        $ad =~ s/\s//go;
        $ad = lc $ad;
        my @domain = split(/[,]+/,$domain);
        @domain = map {
            my $d = $_;
            $d =~ s/\s//go;
            $d =~ s/^\|//o;
            $d =~ s/\|$//o;
            $d = '*@'.$d if $d !~ /\@/o;
            $d =~ s/\./\\\./go;
            $d =~ s/\*/\.\{0,64\}/go;
            $d =~ s/\@/\\@/go;
            lc $d;
        } @domain;
        next unless @domain;
        $domain = join('|',@domain);
        eval{my $d = qr/$domain/;};
        if ($@) {
            $ret .= ConfigShowError( 1, "ERROR: $name contains wrong definition ($_) - $@");
            next;
        }
        $EmailAdminDomains{$ad} .= '|' if $EmailAdminDomains{$ad};
        $EmailAdminDomains{$ad} .= $domain;
    }
    while (my ($k,$v) = each %EmailAdminDomains) {
        eval{$EmailAdminDomains{$k} = qr/$v/;};
        if ($@) {
            $ret .= ConfigShowError( 1, "ERROR: $name regex error for EmailAdmin '$k' - $@");
        }
    }
    return $ret;
}
