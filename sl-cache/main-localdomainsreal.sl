#line 1 "sub main::localdomainsreal"
package main; sub localdomainsreal {
    my $h = shift;
    d("localdomainsreal - $h",1) if $WorkerNumber != 10001;
    $h =~ tr/A-Z/a-z/;
    my $hat; $hat = $1 if $h =~ /(\@[^@]*)/o;
    $h = $1 if $h =~ /\@([^@]*)/o;

    return 1 if $localDomains && ( ($hat && $hat =~ /$LDRE/) || ($h && $h =~ /$LDRE/) );
    return &localLDAPdomain($h);
}
