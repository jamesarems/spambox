#line 1 "sub main::MailLoopOK"
package main; sub MailLoopOK {
    my $fh = shift;
    d("MailLoopOK");
    return 1 unless $detectMailLoop;
    my $count = 0;
    my @myNames = ($myName);
    push @myNames , split(/[\|, ]+/o,$myNameAlso);
    my $myName = '(?:'.join('|', map {my $t = quotemeta($_);$t;} @myNames).')';
    while ( $Con{$fh}->{header} =~ /(Received:\s+from\s\S+\sby\s+$myName\s+with\s+e?smtp(?:sa?\([^()]+\))?\s+\(\Q$version\E\);)/igs ) {
        last if ++$count > $detectMailLoop;
    }
    return 0 if $count > $detectMailLoop;
    return 1;
}
