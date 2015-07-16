#line 1 "sub main::setSSLfailed"
package main; sub setSSLfailed {
    my $ip = shift;
    return unless $banFailedSSLIP;
    return if matchIP($ip,'noBanFailedSSLIP',0,1);
    if (exists $SSLfailed{$ip}) {   # ban if it fails before
        $SSLfailed{$ip} = time;
    } elsif (($banFailedSSLIP & 1) && (matchIP($ip,'acceptAllMail',0,1) or $ip =~ /$IPprivate/o)) {  # give privates one more chance
        $SSLfailed{$ip} = 0;
    } elsif ($banFailedSSLIP & 2) {
        $SSLfailed{$ip} = time;    # ban IP if it fails before
    }
    return;
}
