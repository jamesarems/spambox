#line 1 "sub main::NotSpamTagCheck"
package main; sub NotSpamTagCheck {
    my $fh = shift;
    return unless $fh;
    return unless exists $Con{$fh};
    return unless $NotSpamTag;
    return if $Con{$fh}->{relayok} && ! $noRelayNotSpamTag;
    
    makeSubject($fh);
    while ($Con{$fh}->{subject3} =~ /\b[\'\"\[\(]?([0a-zA-Z2-7]{10})[\'\"\]\)]?\b/og) {
        return if NotSpamTagOK($fh,$1);
    }
}
