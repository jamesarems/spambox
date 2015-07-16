#line 1 "sub main::localdomains"
package main; sub localdomains {
    my $h = shift;
    d("localdomains - $h",1) if $WorkerNumber != 10001;
    $h =~ tr/A-Z/a-z/;
    my $hat; $hat = $1 if $h =~ /(\@[^@]*)/o;
    $h = $1 if $h =~ /\@([^@]*)/o;

    return 1 if $h eq "spambox.local";
    return 1 if $h eq "spambox-nospam.org";

    my ($EBRD) = $EmailBlockReportDomain =~ /^\@*([^@]*)$/o;
    return 1 if ($EBRD && lc($h) eq lc($EBRD));

    return 1 if $localDomains && ( ($hat && $hat =~ /$LDRE/) || ($h && $h =~ /$LDRE/) );
    return &localLDAPdomain($h);
}
