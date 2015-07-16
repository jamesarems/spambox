#line 1 "sub main::ShowWhiteReport"
package main; sub ShowWhiteReport {
    my ( $ad, $this ) = @_;
    d('ShowWhiteReport');
    mlog( 0, "email: ShowWhiteReport: a: $ad ", 1 );

    my $t = time;

    my $list = "Whitelist";

    my $mf           = lc $ad;
    my $mfd; $mfd    = $1 if $mf =~ /\@([^@]*)/o;
    my $mfdd; $mfdd  = $1 if $mf =~ /(\@[^@]*)/o;
    my $alldd        = "$wildcardUser$mfdd";
    my $defaultalldd = "*$mfdd";
    if ( &Whitelist($mf) ) {

        if ( $this->{report} !~ /\Q$mf\E is on Whitelist/ ) {
            $this->{report} .= "\n$mf is on Whitelist\n\n";
        }

    }
    else {
        if ( $this->{report} !~ /\Q$mf\E is not on Whitelist/ ) {
            $this->{report} .= "$mf is not on Whitelist\n";
        }
    }

    if ( &Whitelist( $mf, $this->{mailfrom} ) ) {

        if ( $this->{report} !~ /\Q$mf,$this->{mailfrom}\E is on Whitelist/ ) {
            $this->{report} .= "\n$mf,$this->{mailfrom} is on Whitelist\n\n";
        }

    }
    else {
        if ( $this->{report} !~ /\Q$mf,$this->{mailfrom}\E is not on Whitelist/ ) {
            $this->{report} .= "$mf,$this->{mailfrom} is not on Whitelist\n";
        }
    }

    if ( $Redlist{$mf} ) {

        if ( $this->{report} !~ /\Q$mf\E is on Redlist/ ) {
            $this->{report} .= "\n$mf is on Redlist\n\n";
        }
    }
    if ( matchSL( $mf, 'noProcessing' ) ) {

        if ( $this->{report} !~ /\Q$mf\E is on NoProcessing-List/ ) {
            $this->{report} .= "\n$mf is on NoProcessing-List\n\n";
        }
    }

    if ($npRe) {
        if ( $mf =~ /$npReRE/ ) {

            if ( $this->{report} !~ /\Q$mf\E is on NoProcessing-Regex/ ) {
                $this->{report} .= "\n$mf is in NoProcessing-Regex\n\n";
            }
        }
    }
    if ( $noProcessingDomains && $mf =~ /($NPDRE)/ ) {

        if ( $this->{report} !~ /\Q$1\E is on NoProcessingDomain-List/ ) {
            $this->{report} .= "\n$1 is on NoProcessingDomain-List\n\n";
        }
    }
    if ( &Whitelist($alldd) ) {

        if ( $this->{report} !~ /\Q$alldd\E is on Whitelist/ ) {
            $this->{report} .= "\n$alldd is on Whitelist\n\n";
        }

    }
    if ( &Whitelist($defaultalldd) ) {

        if ( $this->{report} !~ /\Q$defaultalldd\E is on Whitelist/ ) {
            $this->{report} .= "\n$defaultalldd is on Whitelist\n\n";
        }
    }
    if ( $whiteListedDomains && matchRE([$mf,"$this->{mailfrom},$mf"],'whiteListedDomains',1) ) {

        if ( $this->{report} !~ /\Q$lastREmatch\E is on Whitedomain-List/ ) {
            $this->{report} .= "\n$lastREmatch is on Whitedomain-List\n\n";
        }
    }
}
