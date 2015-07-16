#line 1 "sub main::ipv6compress"
package main; sub ipv6compress {
    my $ip = shift;
    if (my @runs = $ip =~ /((?:(?:^|:)(?:0{1,4}))+:?)/g ) {
        my $max = $runs[0];
        for (@runs[1..$#runs]) {
            $max = $_ if length($max) < length;
        }
        $ip =~ s/$max/::/;
    }
    $ip =~ s/:0{1,3}/:/g;
    $ip =~ s/::+/::/o;
    return $ip;
}
