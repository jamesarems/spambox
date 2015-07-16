#line 1 "sub main::BlockReportText"
package main; sub BlockReportText {
    my ( $what, $for, $numdays, $number, $from ) = @_;
    my $file = "$base/reports/blockreport_$what.txt";
    my $text;
    my %slines = ();
    my $f;
    my $section;
    $for  = lc($for);
    $from = lc($from);
    my ($domain) = $for =~ /$EmailAdrRe\@($EmailDomainRe)/o;

    return "report text file $file not found" unless ( open $f, '<',"$file" );
    while (<$f>) {
        next if /^\s*#/o;
        if (/^\s*<([^\/]+)>/o && !$section) {
            $section = lc($1);
        } elsif ( $section && /^\s*<\/$section>/i ) {
            $section = '';
        } elsif ($section) {
            s/REPORTDAYS/$numdays/go;
            s/ASSPNAME/$myName/go;
            s/EMAILADDRESS/$for/go;
            s/NUMBER/$number/go;
            $slines{$section} .= $_;
        }
    }
    close $f;

    $text .= $slines{'all'} if $slines{'all'};
    if (   matchSL( $from, 'EmailAdmins', 1 )
        or matchSL( $from, 'BlockReportAdmins', 1 )
        or lc($from) eq lc($EmailAdminReportsTo)
        or lc($from) eq lc($EmailBlockTo) )
    {
        $text .= $slines{'admins'} if $slines{'admins'};
    } else {
        $text .= $slines{'users'} if $slines{'users'};
    }

    if ( $slines{$for} ) {
        $text .= $slines{$for};
    } elsif ( $slines{$domain} or $slines{ '@' . $domain } ) {
        $text .= $slines{$domain};
        $text .= $slines{ '@' . $domain };
    }

    return $text;
}
